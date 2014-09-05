(function ($, _) {
  var Gmap = function (container) {
    this.$container = $(container);
    this.googleMaps = google.maps;
    this.centerPoint = new this.googleMaps.LatLng(-14.2400732, -53.1805017);
    this.map = null;
    this.marker = null;

    this.render();
    this.setup();

    var that = this;
    this.$container.on('gmap-address:set', function (e, address) {
      that.geocode(address)
    });
  };

  Gmap.prototype.render = function () {
    this.map = new this.googleMaps.Map(this.$container[0], { center: this.centerPoint, zoom: 5 });
  };

  Gmap.prototype.setup = function () {
    var that = this;

    this.googleMaps.event.addListener(this.map, "rightclick", function (event) {
      that.setMarker(event.latLng);
    });

    // Set initial position
    var lng = this.$container.data('lng'),
        lat = this.$container.data('lat');

    if (lng.length != 0 && lat.length != 0) {
      var position = new this.googleMaps.LatLng(lat, lng);

      this.setMarker(position, 15);
    }
  };

  Gmap.prototype.setMarker = function (latLng, zoom) {
    var that = this;

    // Remove previous marker if exists
    if (this.marker) {
      this.marker.setMap(null);
    }

    // Add marker in the clicked place
    this.marker = new this.googleMaps.Marker({
      animation: that.googleMaps.Animation.DROP,
      draggable: true,
      map: that.map,
      position: latLng
    });

    this.$container.trigger('gmap-address:update', latLng);

    this.map.setCenter(latLng);

    if (zoom) {
      this.map.setZoom(zoom);
    }

    // Add dragend event allowing user to drag the marker
    this.googleMaps.event.addListener(this.marker, "dragend", function () {
      var position = that.marker.getPosition();

      that.$container.trigger('gmap-address:update', position);
    });
  };

  Gmap.prototype.geocode = function (address) {
    if (address.trim().length != 0) {
      var that = this,
          geocoder = new this.googleMaps.Geocoder();

      geocoder.geocode({ "address": address }, function (results, status) {
        if (status == that.googleMaps.GeocoderStatus.OK) {
          var position = results[0].geometry.location;

          // Set marker and zoom in
          that.setMarker(position, 15);
        }
      });
    }
  };

  $.fn.gmapAddress = function (option) {
    return this.each(function () {
      var $this = $(this),
          data = $this.data('gmap-address');

      if (!data) $this.data('gmap-address', (data = new Gmap(this)))
      if (typeof option == 'string') data[option]()
    });
  };
})(window.jQuery, window._);
