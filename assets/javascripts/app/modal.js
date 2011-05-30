/*jslint indent: 2, regexp: false */
/*globals $, Control, Element, Class, window */
var Backlogs = (function () {
  var Modal, width;

  width = function () {
    var max = 800;

    if (window.document.viewport.getWidth() < max) {
      return max - 100;
    }
    else {
      return max;
    }
  };

  Modal = Class.create(Control.Modal, {
    initialize : function ($super, container, options) {
      Modal.InstanceMethods.beforeInitialize.bind(this)();
      $super(container, Object.extend(Object.clone(Modal.defaultOptions), options || {}));
    },

    position : function ($super, event) {
      $super(event);
      this.fixPosition();
    },

    ensureInBounds : function ($super) {
      $super();
      this.fixPosition();
    },

    fixPosition : function () {
      var currentTop = this.container.getStyle('top');
      if (currentTop && currentTop.replace(/[^\d]*/g, '') === '0') {
        this.container.setStyle({top: (window.document.viewport.getScrollOffsets().top + 50) + 'px'});
      }
    }
  });

  Object.extend(Modal, {
    defaultOptions : {
      overlayOpacity: 0.75,
      method:    'get',
      className: 'modal',
      fade:      true,
      position:  'center_once',
      width :    width
    },

    Observers : {
      beforeOpen : function () {
        var closeButton = new Element('div', {'id' : 'livepipe-modal-closer'});

        this.container.appendChild(closeButton);
        closeButton.observe('click', function () {
          if (Control.Modal.current) {
            Control.Modal.current.close();
          }
        });
      },
      onError : function (klass, error) {
        this.isOpen = true; // assume, we are open, otherwise, we cannot be closed.
        this.close();
        this.remoteContentLoaded = false;
      }
    },

    InstanceMethods : {
      beforeInitialize : function () {
        this.observe('beforeOpen', Modal.Observers.beforeOpen.bind(this));
        this.observe('onFailure',  Modal.Observers.onError.bind(this));
      }
    }
  });

  Control.Window.baseZIndex = 50;
  Control.Overlay.styles.zIndex = 49;
  Control.Overlay.ieStyles.zIndex = 49;
  return {
    Modal : Modal
  };
}());