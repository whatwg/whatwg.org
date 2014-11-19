/* Usage: include a link like:
 * <a href=".../enter_bug.cgi?...">file a bug</a>
 * (use id="file-bug-link" if the URL doesn't contain "/enter_bug.cgi?")
 * and also include the following:
 * <script src=https://resources.whatwg.org/file-bug.js async></script>
 * If you don't want the script to inject styles, use a data-no-style=""
 * attribute on the script element.
 */
(function(){
  function getUrl() {
    var url = '';
    if (location.protocol == 'file:' || location.hostname == 'localhost') {
      // use "This Version:" link in the header if there is one
      var dt = document.querySelector('dt');
      if (dt.textContent.indexOf('This Version:') != -1 && dt.nextElementSibling && dt.nextElementSibling.firstElementChild instanceof HTMLAnchorElement)
        url += dt.nextElementSibling.firstElementChild.href;
    } else {
      url += location.protocol + '//' + location.host + location.pathname + location.search;
    }
    return url;
  }
  function findLinkOrPoll() {
    var link = document.querySelector('a[href*="/enter_bug.cgi?"], #file-bug-link');
    if (link) {
      init(link);
    } else if (document.readyState !== 'complete') {
      setTimeout(findLinkOrPoll, 250);
    } else {
      throw new Error('No file-bug-link found.');
    }
  }
  function init(link) {
    var prevSelection = '';
    var originalHref = link.href;
    var bugLink = document.createElement('a');
    bugLink.href = originalHref + '&short_desc=&comment=' + encodeURIComponent(getUrl() + '\n\n');
    bugLink.accessKey = '1';
    bugLink.className = 'bug-link';
    bugLink.textContent = 'File a bug about the selected text';
    link.parentNode.appendChild(bugLink);
    if (!document.querySelector('script[data-no-style][src$="/file-bug.js"]')) {
      var style = document.createElement('style');
      style.textContent = '.bug-link { position:fixed; bottom:0; left:0; background:rgba(255,255,255,0.8) !important; width:115px; font-size:smaller; padding:0 10px; z-index:1; text-decoration:underline }';
      document.head.appendChild(style);
    }
    onmouseup = onkeyup = function(e){
      var selectionObj = getSelection();
      var selection = String(selectionObj);
      if (selection == prevSelection) {
        return;
      }
      prevSelection = selection;
      var node = e.target;
      if (selectionObj.anchorNode) {
        node = selectionObj.anchorNode;
        if (selectionObj.focusNode && selectionObj.focusNode.compareDocumentPosition) {
          var compare = selectionObj.focusNode.compareDocumentPosition(selectionObj.anchorNode);
          if (compare == 20 || compare == 4) { // descendant or following
            node = selectionObj.focusNode;
          }
        }
      }
      while (node && !node.id) {
        node = node.previousSibling || node.parentNode;
      }
      var summary = selection.replace(/\n/g, ' ');
      if (summary.length > 50) {
        summary = summary.substr(0,47)+'...';
      }
      if (summary) {
        summary = '"' + summary + '" ';
      }
      if (selection.length > 1000) {
        selection = selection.substr(0,997)+'...';
      }
      if (selection) {
        selection = '[[\n' + selection + '\n]]\n\n';
      }
      var url = getUrl();
      if (node) {
        url += '#'+node.id;
      }
      bugLink.href = originalHref + '&short_desc=' + encodeURIComponent(summary) + '&comment=' + encodeURIComponent(url + '\n\n' + selection);
    };
  }
  findLinkOrPoll();
})();
