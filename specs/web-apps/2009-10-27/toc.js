function filterToc(toc, callback) {
  var li = toc.firstChild;
  var allmatched = true;
  while (li) {
    if (li.nodeType == Node.ELEMENT_NODE) {
      var id = li.firstChild.hash.substr(1);
      var target = document.getElementById(id);
      var matched = false;
      while (target && !matched && target != document.body) {
        if (target.className == 'impl')
          matched = true;
        else
          target = target.parentNode;
      }
      if (matched) {
        li.className = 'impl';
      } else {
        allmatched = false;
        var ol = li.getElementsByTagName('ol')[0];
        if (ol)
          filterToc(ol);
      }
    }
    li = li.nextSibling;
  }
  if (allmatched)
    toc.className += ' impl';
}

function initToc() {
  var ols = document.getElementsByTagName('ol');
  var toc;
  for (var index = 0; index < ols.length; index += 1) {
    if (ols[index].className == 'toc') {
      toc = ols[index];
      break;
    }
  }
  if (!toc)
    throw "Failed to find TOC";

  // filter 'impl' bits
  filterToc(toc);

  // generate short toc once it's done
  var newtoc = document.createElement('ol');
  newtoc.className = 'brief toc';
  var li = toc.firstChild;
  var id = 1;
  while (li) {
    if (li.nodeType == Node.ELEMENT_NODE) {
      var newli = document.createElement('li');
      newli.className = li.className;
      var newa = li.firstChild.cloneNode(true);
      li.id = 'auto-toc-' + id;
      newa.href = '#auto-toc-' + id;
      newli.appendChild(newa);
      newtoc.appendChild(newli);
      id += 1;
    }
    li = li.nextSibling;
  }
  toc.parentNode.insertBefore(newtoc, toc);
  var h3 = document.createElement('h3');
  h3.textContent = 'Full table of contents';
  toc.parentNode.insertBefore(h3, toc);
}

// setup
var tocTimer = new Date();
initToc();
if (getCookie('profile') == '1')
  document.getElementsByTagName('h2')[0].textContent += '; toc.js: ' + (new Date() - tocTimer) + 'ms';
