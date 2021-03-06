angular.module('rsfIndex2015').factory 'MapData', ($q, $http, $translate, $filter)->
  $q.all(
    coordinates: $http.get("assets/json/countries.coordinates.json")
    topojson   : $http.get("assets/json/countries.topo.json")
    names      : $http.get("assets/json/countries.names.json")
    ranking    : $http.get("assets/json/countries.ranking.json")
    count      : $http.get("assets/json/countries.count.json")
    # Do not start before the translation is loaded
    decimal    : ($translate)-> $translate('decimal_mark')
  ).then (hash)->
    # Color scale
    colorScale = (value)->
      colors = ['#FFFFFF', '#FAE417', '#F1980B', '#DA032E', '#000000']
      positions = [0, 15, 25, 35, 55]
      for position, index in positions
        if value < position
          return colors[index - 1]
      return colors[4]
    # Prepare data
    angular.forEach hash.ranking.data, (rank)->
      # Convert every sortable key to numbers
      for key of rank
        # Must have a value
        if ["", null, undefined].indexOf(rank[key]) is -1
          # Value must be a number to be casted
          rank[key] = 1 * rank[key] unless isNaN rank[key]
    # Create an object with every country to allow fast country lookup
    rankingTree  = _.reduce(hash.ranking.data, (result, country)->
      # Pre-calculate 2015 colors
      country["score_2015_color"] = colorScale country["score_2015"]
      # Save the country with it code as key
      result[country.country_code] = country
      result
    , {})
    # Convert name to titlecase
    namesTree = _.reduce( hash.names.data, (result, country)->
      ###
      for key of country
        # Only name attribute
        if key.indexOf('country_name_') is 0
          # Use the titlecase filter
          country[key] = country[key] or ""
      ###
      result[country.iso_3] = country
      result
    , {})
    # Convert count by year into a tree
    countTree = _.reduce( hash.count.data, (result, value)->
      result[value.year] = 1* value.count
      result
    , {})
    # Returns an object
    coordinates: hash.coordinates.data
    topojson   : hash.topojson.data
    ranking    : hash.ranking.data
    names      : namesTree
    count      : countTree
    brewer     : colorScale
    # Help function to retreive country data
    country: (code)->
      code = if code.country_code? then code.country_code else code
      code = code.toUpperCase()
      # Get the center of the country
      center: -> _.findWhere hash.coordinates.data, code: code
      # Get the names of the country
      names: -> namesTree[code]
      # Get the name of the country in the given language
      name: (lang=$translate.use() or "en")->
        key = 'country_name_' + lang.toLowerCase()
        if namesTree[code]? then namesTree[code][key] else ""
      # Get the url of the country
      url: (lang=$translate.use() or "en")-> rankingTree[code]["url_country_page_" + lang]
      # Get the ranking of the given country
      rank: -> rankingTree[code]
      # True if the country is ranked in the given year
      hasRanking: (year=2015)-> rankingTree[code] and rankingTree[code]["ranking_" + year]
      # Compute the color of the country
      color: (year=2015)->
        colorKey = "score_" + year + "_color"
        # Return null if no score for this country
        if rankingTree[code]?
          # Should we use a pre-calculated color?
          if rankingTree[code][colorKey]?
            # Yes we do!
            rankingTree[code][colorKey]
          else
            # Calculate the color now
            color = colorScale( rankingTree[code]["score_" + year] )
            # And save it
            rankingTree[code][colorKey] = color
        else
          null
