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

class RbTaskboardsController < RbApplicationController
  unloadable

  menu_item :backlogs

  helper :taskboards

  def show
    @statuses     = Type.find_by_id(Task.type).statuses
    @story_ids    = @sprint.stories(@project).map{|s| s.id}
    @last_updated = Task.find(:first,
                              :conditions => ["parent_id in (?)", @story_ids],
                              :order      => "updated_at DESC")
  end

  def create_tasks
    allowed_story_ids    = @sprint.stories(@project).map{|s| s.id}
    allowed_user_ids    = @project.possible_assignees.map{|u| u.id}

    story_ids     = params[:story_ids].split('-').map{|i|i.to_i}
    user_ids      = params[:user_ids].split('-').map{|i|i.to_i}

    story_ids.reject! { |x| not allowed_story_ids.include? x }
    user_ids.reject! { |x| not allowed_user_ids.include? x }

    if story_ids.size > 0 and user_ids.size > 0
      msg, created = Task.create_tasks_for_stories story_ids, user_ids

      if msg == 'OK'
        render :json => { :status => 'OK', :message => "Created #{created} tasks" }
      else
        render :json => { :status => msg, :message => msg.split(';') }
      end
    else
      render :json => { :status => 'Error', :message => 'Invalid input - ' + story_ids.inspect + '/' + allowed_story_ids.inspect + ' | ' + user_ids.inspect + '/' + allowed_user_ids.inspect }
    end
  end

  def default_breadcrumb
    l(:label_backlogs)
  end
end
