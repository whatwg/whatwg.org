resources.whatwg.org
==============================================

Logo creation
-----------------

The majority of PNG logos have been created using:

* `inkscape --export-type=png <file>.svg -w 500 -h 500` (see [Inkscape](https://inkscape.org/)).
* Running [ImageOptim](https://imageoptim.com/).

These tools can be useful to reduce the size of an SVG logo:

* https://jakearchibald.github.io/svgomg/
* https://simon.html5.org/tools/js/svg-optimizer/ (lossy)

Stylesheets Organization
------------------------

There are four broud groups of documents produced by WHATWG: HTML (produced by Wattsi), the HTML Dev edition (stripped-down, differently-styled version of HTML), all other specs (produced by Bikeshed), and Review Drafts (even more stripped down versions of specs, both Wattsi- and Bikeshed-generated).

The various CSS files apply across these categories as follows:

<table>
  <thead>
    <tr><td><th>HTML<th>HTML Dev<th>Other Specs<th>Review Drafts
  </thead>
  <tr><th>standard-shared-with-dev.css<td>✓<td>✓<td>✓<td>
  <tr><th>standard.css<td>✓<td><td>✓<td>
  <tr><th>spec.css<td>✓<td><td>✓<td>✓
</table>

Additionally, HTML, HTML Dev, and Review Drafts have their own dedicated stylesheets. HTML and HTML Dev's are in the HTML repo (`styles.css` and `dev/styles.css`), Review Drafts' is here (`review-drafts.css`). For any styling specific to "Other Specs" that shouldn't apply to Review Drafts, put it in `specs.css` and negate it in `review-drafts.css`.

Contributors
------------

* Anne van Kesteren
* Domenic Denicola
* Henri Sivonen
* Janessa Det
* Matthew Raymond
* Robbert Broersma
* Simon Pieters
* Tab Atkins
* Terin Stock

License (excluding browser-logos and fonts)
-------

[![CC0](http://i.creativecommons.org/p/zero/1.0/80x15.png)](http://creativecommons.org/publicdomain/zero/1.0/)
To the extent possible under law, the contributors have waived all copyright and related
or neighboring rights to this work.

`logo-websockets.svg` and `logo-websockets.png` are based on the "Connectivity" logo from the
[W3C HTML5 logo project](https://www.w3.org/html/logo/).
([CC BY 3.0](https://creativecommons.org/licenses/by/3.0/))
