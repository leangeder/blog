// Define requirement
var gulp = require('gulp');
var plugins = require('gulp-load-plugins')();
var browserSync = require('browser-sync').create();

// Define variables
// var source = './scss';
var destination = 'static/css'
// var lib = ['node_modules/foundation-sites/scss','node_modules/foundation-sites/scss/components','node_modules/foundation-sites/scss/forms','node_modules/foundation-sites/scss/grid','node_modules/foundation-sites/scss/settings','node_modules/foundation-sites/scss/typography','node_modules/foundation-sites/scss/util']
var sassPaths = [
  'node_modules/foundation-sites/scss',
  'node_modules/foundation-sites/scss/settings'
];

// Building task + feature
gulp.task('css', function () {
    return gulp.src('scss/app.scss')
        .pipe(plugins.sass({
          includePaths: sassPaths
        }).on('error',plugins.sass.logError))
        // .pipe(plugins.sass().on('error',plugins.sass.logError))
        .pipe(plugins.csscomb())
        .pipe(plugins.cssbeautify({indent: '  '}))
        .pipe(plugins.autoprefixer())
        .pipe(gulp.dest(destination));
});

// // Minification task
// gulp.task('minify', function () {
//     return gulp.src(destination + '/*.css')
//         .pipe(plugins.csso())
//         .pipe(plugins.rename({
//           suffix: '.min'
//           }))
//         .pipe(gulp.dest(destination));
// });

// Building task
gulp.task('build', ['css']);

// Production task
gulp.task('prod', ['build',  'minify']);

// // Reload task
// gulp.task('reload', function () {
//   browserSync.reload();
//   done();
// });

// // Watch task
// gulp.task('watch', function () {
//     // Serve files from the root of this project
//     browserSync.init({
//         server: {
//             baseDir: "./templates/"
//         }
//     });
//     gulp.watch(source + '**/*.scss', ['reload', 'build']);
//     gulp.watch(source + '**/*.html', ['reload', 'build']);
// });

gulp.task('server', ['build'], function() {

    browserSync.init({
        server: {
          baseDir: "./",
          routes: {
            "/": "./templates",
            "/css": "../static/css",
            "/js": "../static/js",
            "/img": "../static/img"
          }
        }
    });

    gulp.watch('./scss/app.scss', ['build']);
    gulp.watch('templates/*.html').on('change', browserSync.reload);
});


// Default task
gulp.task('default', ['server']);
