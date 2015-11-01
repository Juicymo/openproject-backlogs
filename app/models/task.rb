#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'date'

class Task < WorkPackage
  unloadable

  extend OpenProject::Backlogs::Mixins::PreventIssueSti

  def self.type
    task_type = Setting.plugin_openproject_backlogs["task_type"]
    task_type.blank? ? nil : task_type.to_i
  end

  # This method is used by Backlogs::List. It ensures, that tasks and stories
  # follow a similar interface
  def self.types
    [self.type]
  end

  def self.create_tasks_for_stories story_ids, user_ids
    raw_stories = Story.find(story_ids).map{|s| [s.id, s]}
    stories = Hash[raw_stories]

    raw_users = User.find(user_ids).map{|u| [u.id, u]}
    users = Hash[raw_users]
    user_count = user_ids.size

    created = 0
    ok = true
    errors = []
    story_ids.each do |story_id|
      story = stories[story_id]
      story_points_to_be_divided = 0
      if story.story_points.present?
        tasks = story.tasks
        assigned_story_points = tasks.any? ? story.tasks.map{|t|t.story_points.present? ? t.story_points : 0}.reduce(:+) : 0
        story_points_to_be_divided = story.story_points - assigned_story_points
      end

      is_first_user = true
      user_ids.each do |user_id|
        user = users[user_id]
        task = new

        task.author = User.current
        task.assigned_to = user
        task.type_id = Task.type

        task.project_id = story.project_id
        task.fixed_version = story.fixed_version
        task.subject = story.subject.gsub('{ANCHOR}', '')

        task.category = story.category if story.category.present?
        task.description = story.description if story.description.present?
        task.priority = story.priority if story.priority.present?
        task.responsible = story.responsible if story.responsible.present?
        task.start_date = story.start_date if story.start_date.present?
        task.due_date = story.due_date if story.due_date.present?

        if story.story_points.present?
          if story_points_to_be_divided > 0
            points = story_points_to_be_divided / user_count

            if is_first_user
              addition = story_points_to_be_divided % user_count
              points += addition
            end

            task.story_points = points
          else
            task.story_points = 0
          end
        end

        task.parent_id = story.id

        if !task.save
          errors << task.errors.full_messages
        else
          created += 1
          is_first_user = false
        end
      end
    end

    if ok
      return "OK", created
    else
      return errors.join(';'), created
    end
  end

  def self.create_with_relationships(params, project_id)
    task = new

    task.author = User.current
    task.project_id = project_id
    task.type_id = Task.type

    task.safe_attributes = params

    if task.save
      task.move_after params[:prev]
    end

    return task
  end

  def self.tasks_for(story_id)
    Task.find_all_by_parent_id(story_id, :order => :lft).each_with_index do |task, i|
      task.rank = i + 1
    end
  end

  def status_id=(id)
    super
    self.remaining_hours = 0 if Status.find(id).is_closed?
  end

  def update_with_relationships(params, is_impediment = false)
    self.safe_attributes = params

    save.tap do |result|
      move_after(params[:prev]) if result
    end
  end

  # Assumes the task is already under the same story as 'prev_id'
  def move_after(prev_id)
    if prev_id.blank?
      sib = self.siblings
      move_to_left_of(sib[0].id) if sib.any?
    else
      move_to_right_of(prev_id)
    end
  end

  def rank=(r)
    @rank = r
  end

  def rank
    @rank ||= WorkPackage.count(:conditions => ['type_id = ? and not parent_id is NULL and root_id = ? and lft <= ?', Task.type, story_id, self.lft])
    return @rank
  end
end
