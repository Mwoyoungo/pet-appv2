// Google Maps Web Service - Called from Flutter via JS interop
window.MapsWebService = {
  autocompleteService: null,
  placesService: null,
  directionsService: null,

  init: function() {
    if (window.google && window.google.maps) {
      this.autocompleteService = new window.google.maps.places.AutocompleteService();
      this.directionsService = new window.google.maps.DirectionsService();
      console.log('[MapsWebService] Initialized');
    }
  },

  // Get autocomplete suggestions
  getSuggestions: function(input, callback) {
    if (!this.autocompleteService) {
      this.init();
    }
    
    if (!this.autocompleteService) {
      console.error('[MapsWebService] AutocompleteService not available');
      callback([]);
      return;
    }

    this.autocompleteService.getPlacePredictions(
      { input: input, types: ['geocode'] },
      function(predictions, status) {
        if (status === 'OK' || status === 'ZERO_RESULTS') {
          const results = predictions ? predictions.map(function(p) {
            return {
              description: p.description,
              placeId: p.place_id,
              mainText: p.structured_formatting ? p.structured_formatting.main_text : p.description
            };
          }) : [];
          console.log('[MapsWebService] Got ' + results.length + ' suggestions');
          callback(results);
        } else {
          console.error('[MapsWebService] Autocomplete error:', status);
          callback([]);
        }
      }
    );
  },

  // Get place details (lat/lng)
  getPlaceDetails: function(placeId, callback) {
    if (!window.google || !window.google.maps) {
      callback(null);
      return;
    }

    // Create a dummy map element for PlacesService
    const dummyDiv = document.createElement('div');
    const map = new window.google.maps.Map(dummyDiv, {
      center: { lat: 0, lng: 0 },
      zoom: 1
    });
    
    const service = new window.google.maps.places.PlacesService(map);
    
    service.getDetails(
      { placeId: placeId, fields: ['geometry'] },
      function(place, status) {
        if (status === 'OK' && place.geometry) {
          callback({
            lat: place.geometry.location.lat(),
            lng: place.geometry.location.lng()
          });
        } else {
          console.error('[MapsWebService] Place details error:', status);
          callback(null);
        }
      }
    );
  },

  // Reverse geocode (lat/lng to address)
  reverseGeocode: function(lat, lng, callback) {
    if (!window.google || !window.google.maps) {
      callback(null);
      return;
    }

    const geocoder = new window.google.maps.Geocoder();
    
    geocoder.geocode(
      { location: { lat: lat, lng: lng } },
      function(results, status) {
        if (status === 'OK' && results && results.length > 0) {
          const result = results[0];
          const address = result.formatted_address;
          
          // Extract components
          let city = '';
          let subLocality = '';
          for (let i = 0; i < result.address_components.length; i++) {
            const component = result.address_components[i];
            if (component.types.includes('locality')) {
              city = component.long_name;
            }
            if (component.types.includes('sublocality') || component.types.includes('sublocality_level_1')) {
              subLocality = component.long_name;
            }
          }
          
          callback({
            address: address,
            city: subLocality || city || 'Unknown',
            fullAddress: address
          });
        } else {
          console.error('[MapsWebService] Geocoding error:', status);
          callback(null);
        }
      }
    );
  },

  // Get directions
  getDirections: function(originLat, originLng, destLat, destLng, callback) {
    if (!this.directionsService) {
      this.init();
    }

    if (!this.directionsService) {
      callback(null);
      return;
    }

    this.directionsService.route(
      {
        origin: { lat: originLat, lng: originLng },
        destination: { lat: destLat, lng: destLng },
        travelMode: 'DRIVING'
      },
      function(response, status) {
        if (status === 'OK') {
          const route = response.routes[0];
          const leg = route.legs[0];
          
          // Extract polyline points
          const points = [];
          const path = route.overview_path;
          for (let i = 0; i < path.length; i++) {
            points.push({
              lat: path[i].lat(),
              lng: path[i].lng()
            });
          }

          callback({
            distanceText: leg.distance.text,
            distanceValue: leg.distance.value,
            durationText: leg.duration.text,
            points: points
          });
        } else {
          console.error('[MapsWebService] Directions error:', status);
          callback(null);
        }
      }
    );
  }
};

// Initialize when Google Maps is ready
if (window.google && window.google.maps) {
  window.MapsWebService.init();
} else {
  // Wait for Google Maps to load
  window.addEventListener('load', function() {
    setTimeout(function() {
      window.MapsWebService.init();
    }, 1000);
  });
}
