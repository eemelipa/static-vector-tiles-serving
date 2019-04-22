LAYER := Road

all: generate-geojson generate-tiles start-server

regenerate-geojson: clean generate-geojson

generate-geojson:
	@echo ==================
	@echo Generating geojson
	@echo ==================

	mkdir -p build/shapefiles

	find "src" | grep "\.zip" | xargs -n1 unzip -u -d "build/shapefiles"
	find "build/shapefiles" | grep "_${LAYER}.shp" > "build/${LAYER}_shapefiles.txt"
	@if ! [ -f build/${LAYER}.shp ]; then \
		echo Generating build/${LAYER}.shp file; \
		ogr2ogr -progress -f 'ESRI Shapefile' "build/${LAYER}.shp" -nln "${LAYER}" "`cat "build/${LAYER}_shapefiles.txt" | head -n 1`"; \
	fi
	mkdir -p build/geojson
	@if ! [ -f build/geojson/${LAYER}.json ]; then \
		echo Generating build/geojson/${LAYER}.json file; \
		ogr2ogr -progress -dim 2 -f 'GeoJSON' -s_srs "+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.999601 +x_0=400000 +y_0=-100000 +ellps=airy +units=m +no_defs +nadgrids=./src/OSTN02_NTv2.gsb" -t_srs 'EPSG:4326' "build/geojson/${LAYER}.json" "build/${LAYER}.shp"; \
	fi

generate-tiles:
	@echo ==================
	@echo Generatig tiles
	@echo ==================

	mkdir -p build/www
	tippecanoe --force --no-feature-limit --no-tile-size-limit --exclude-all --minimum-zoom=5 --maximum-zoom=g --output-to-directory "build/www/tiles" `find ./build/geojson -type f | grep .json`; \

start-server:
	@echo ==================
	@echo Starting server
	@echo ==================

	mkdir -p build/www
	cp -r src/www/ build/www
	cp src/gzip.js build/gzip.js
	npm install
	npm start

clean:
	rm -r build
