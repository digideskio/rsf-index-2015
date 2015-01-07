angular.module("rsfIndex2015").controller "MapCtrl", ($scope, $q, leafletData)->

  countryMarker = null
  featureFillScale = chroma.scale(['#FFFFFF', '#F1FB8D', '#EA191E', '#9F042B', '#410E2E']).domain [0, 100]

  featureStyle = (feature)->
    fillColor: featureFillScale( Math.round(Math.random() * 100) )
    weight: 1,
    opacity: 1,
    color: 'white',
    fillOpacity: 0.7

  updateMapView = (country, zoom)->
    # Do not zoom pn empty value
    return unless country?
    # Retreive map instance
    leafletData.getMap().then (map)->
      # Find the coordinate of the given country
      center = _.findWhere $scope.data.coordinates, code: country
      # Zoom to the current place
      map.setView L.latLng(center.lat, center.lng, zoom)
      # Remove existing marker
      map.removeLayer countryMarker if countryMarker isnt null
      # Create a marker on the country
      countryMarker = L.marker([center.lat, center.lng])
        .addTo(map)
        .bindPopup(country)
        .openPopup()

  # Map settings
  $scope.settings =
    center:
      lat: 40.095
      lng: -3.823
      zoom: 2
    defaults:
      scrollWheelZoom: no
    geojson:
      data: $scope.data.geojson
      style: featureStyle
  # Watch change on the selected country
  $scope.$watch('country', (country)->
    updateMapView country, 4
  , yes)
  # Watch click on a geojson feature
  $scope.$on 'leafletDirectiveMap.geojsonClick', (ev, feature)->
    # Retreive map instance
    updateMapView feature.id
