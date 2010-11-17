# Récupère les information de géocodage avec l'API Google Maps
# Prend en entrée le nom d'un fichier json d'entrée et le nom d'un fichier json en sortie
# Les informations de géolocalisation sont stockées dans l'attribute "geolocalisation"
# et l'adresse formattée est stockée dans "adresse_formattee"

if ARGV.length != 2
  raise 'Deux noms de fichier à spécifier'
end

require 'rubygems'
require 'json'
require 'rest-client'

adresses = JSON.parse IO.read(ARGV[0])

def query adresse
  JSON.parse(RestClient.get 'http://maps.googleapis.com/maps/api/geocode/json',
                            {:params =>
                                    {:region => :FR,
                                     :language => :fr,
                                     :sensor => :false,
                                     :address => adresse}})
end

interrupted = false
trap('INT') { interrupted = true }

delay = 0

adresses.each_value do |entry|
  if interrupted
    File.open(ARGV[1], 'w') { |f| f.write(JSON.pretty_generate(adresses)) }
    exit 'Interrompu'
  end

  if entry.has_key?('adresse_normalisee') && (!entry.has_key?('geolocalisation'))
    adresse = entry['adresse_normalisee']

    result = query(adresse)
    while result['status'] == 'OVER_QUERY_LIMIT'
      delay += 10
      sleep delay
      result = query(adresse)
    end

    status = result['status']
    p "#{status} #{adresse}"

    entry['geolocalisation'] = geolocalisation = {'status' => status}
    if status == 'OK'
      geolocalisation['partial_match'] = result['results'][0]['partial_match']
      geolocalisation['location'] = result['results'][0]['geometry']['location']
      geolocalisation['location_type'] = result['results'][0]['geometry']['location_type']
      entry['adresse_formattee'] = result['results'][0]['formatted_address']
    end
    sleep delay
  end
end

File.open(ARGV[1], 'w') { |f| f.write(JSON.pretty_generate(adresses)) }