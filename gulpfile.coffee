gulp = require 'gulp'
util = require 'gulp-util'
glob = require 'glob'
path = require 'path'
rename = require 'gulp-rename'
minimist = require 'minimist'
express = require 'express'
merge = require 'merge2'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'

cssmin = require 'gulp-cssmin'
sass = require 'gulp-sass'
sourcemaps = require 'gulp-sourcemaps'
coffee = require 'gulp-coffee'
browserify = require 'browserify'
# browserify後にjshintするとエラーいっぱい
# jshint = require 'gulp-jshint'
uglify = require 'gulp-uglify'
imagemin = require 'gulp-imagemin'


options = minimist process.argv
is_production = -> options.env == 'production'
if_production = (t, f) -> 
  if options.env == 'production' then t else f || util.noop()
if_not_production = (t, f) -> 
  if options.env != 'production' then t else f || util.noop()


gulp.task 'styles', ->
  src1 = gulp.src 'assets/css/*.css'
    .pipe if_production cssmin()
  src2 = gulp.src 'assets/css/*.scss'
    .pipe if_not_production sourcemaps.init()
    .pipe if_production sass({outputStyle:'compressed'}), sass()
    .pipe if_not_production sourcemaps.write()
  merge src1, src2
    .pipe gulp.dest 'public/css'

gulp.task 'lib', ->
  gulp.src 'assets/lib/**/*.coffee'
    .pipe coffee()
    .pipe gulp.dest 'assets/lib'

gulp.task 'scripts', ['lib'], ->
  glob 'assets/js/*', (err, files) ->
    # TODO: handle error
    files.map (file) ->
      # now just support .js and .coffee files
      throw "Unsupported script: #{file}" unless path.extname(file) in [ '.js', '.coffee' ]
      opts =
        debug: !is_production()
      browserify file, opts
        .bundle()
        .pipe source path.basename file
        .pipe if_production buffer()
        .pipe rename { extname: '.js' } # for .coffee files
        # .pipe jshint()
        # .pipe jshint.reporter 'default'
        .pipe if_production uglify()
        .pipe gulp.dest 'public/js'

gulp.task 'images', ->
  gulp.src 'assets/img/**/*'
    .pipe imagemin()
    .pipe gulp.dest 'public/img'

gulp.task 'watch', ->
  gulp.watch 'assets/css/**/*', ['styles']
  gulp.watch 'assets/js/*', ['scripts']
  gulp.watch 'assets/img/**/*', ['images']

gulp.task 'server', ->
  server = express()
  server.use express.static 'public'
  server.listen 8080

gulp.task 'default', [
  'styles'
  'scripts'
  'images'
  'watch'
]

gulp.task 'staging', [
]

gulp.task 'production', [
]
