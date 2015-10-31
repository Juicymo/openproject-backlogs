//-- copyright
// OpenProject Backlogs Plugin
//
// Copyright (C)2013-2014 the OpenProject Foundation (OPF)
// Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
// Copyright (C)2010-2011 friflaj
// Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
// Copyright (C)2009-2010 Mark Maglana
// Copyright (C)2009 Joe Heck, Nate Lowrie
//
// This program is free software; you can redistribute it and/or modify it under
// the terms of the GNU General Public License version 3.
//
// OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
// The copyright follows:
// Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
// Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

// Initialize the backlogs after DOM is loaded
jQuery(function ($) {

  jQuery.Color.fn.contrastColor = function() {
      var r = this._rgba[0], g = this._rgba[1], b = this._rgba[2];
      return (((r*299)+(g*587)+(b*144))/1000) >= 131.5 ? "black" : "white";
  };

  // Initialize each backlog
  $('.backlog').each(function (index) {
    // 'this' refers to an element with class="backlog"
    RB.Factory.initialize(RB.Backlog, this);
  });

  // Workaround for IE7
  if ($.browser.msie && $.browser.version <= 7) {
    var z = 50;
    $('.backlog, .header').each(function () {
      $(this).css('z-index', z);
      z -= 1;
    });
  }

  $('.backlog .toggler').on('click',function(){
    $(this).toggleClass('closed');
    $(this).parents('.backlog').find('ul.stories').toggleClass('closed');
  });

    $(document).tooltip({
        items: "li.model.story div.subject.story-tooltip, div.story.story-tooltip",
        content: function() {
            var element = $(this);

            if (element.is("li.model.story div.subject.story-tooltip")) {
                var encoded = element.siblings(".meta").first().children("div.tooltip-content").first().html(); //element.attr("data-story-tooltip");
                //var decoded = $("<div/>").html(encoded).text();
                return encoded;
            }
            else if (element.is("div.story.story-tooltip")) {
                var element = $(this);
                var content = element.children("div.story-tooltip-content").first().html();
                return content;
            }
        },
        position: {
            my: "left center",
            at: "right center"
        },
        hide: false,
        show: false
    });
});
