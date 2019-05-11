// Usage: include a link like `<a href="https://github.com/whatwg/{my-repo}/issues/new">file an issue</a>`, or give it
// `id="file-issue-link"` instead. The URL can include ?title=... to give a title prefix. Then include this script with
// `<script src="https://resources.whatwg.org/file-issue.js" async></script>` after that link. Style the element using
// the selector `.selected-text-file-an-issue`.
//
// If you don't have a file an issue link on your spec (e.g. for a spec split into multiple documents), you can use
// a `data-file-issue-url=""` attribute on the `<script>` tag, and include this script right after the `<body>` tag.
//
// If you want to include this script in `head`, use `defer` instead of `async`.

(function () {
  'use strict';

  let originalFilingURL = getOriginalFilingURL();
  let titlePrefix = '';
  const queryParamIndex = originalFilingURL.indexOf('?title=');
  if (queryParamIndex != -1) {
    titlePrefix = decodeURIComponent(originalFilingURL.substr(queryParamIndex + '?title='.length));
    originalFilingURL = originalFilingURL.substr(0, queryParamIndex);
  }

  const specURL = getSpecURL();

  const fileLink = document.createElement('a');
  fileLink.href = originalFilingURL;
  fileLink.accessKey = '1';
  fileLink.className = 'selected-text-file-an-issue';
  fileLink.textContent = 'File an issue about the selected text';
  fileLink.onclick = e => {
    fileLink.href = getFilingURL(originalFilingURL, window.getSelection());
  };

  document.body.prepend(fileLink);

  function getOriginalFilingURL() {
    const dataAttr = document.currentScript.getAttribute("data-file-issue-url");
    if (dataAttr) {
      return dataAttr;
    }

    const link = document.querySelector('#file-issue-link, a[href$="/issues/new"], a[href*="/issues/new?title="]');
    if (link) {
      return link.href;
    }

    throw new Error('No "file an issue" link found and no data-file-issue-url attribute present on the script');
  }

  function getSpecURL() {
    const link = document.getElementById('commit-snapshot-link');
    if (link) {
      return link.href;
    }
    return window.location.href;
  }

  function getFilingURL(originalFilingURL, selection) {
    const bugData = getBugData(selection);
    return originalFilingURL + '?title=' + encodeURIComponent(bugData.title) + '&body=' +
           encodeURIComponent(bugData.body);
  }

  function getBugData(selection) {
    const selectionText = selection.toString();
    const url = getURLToReport(selection);

    return {
      title: getTitle(selectionText),
      body: getBody(url, selectionText)
    };
  }

  function escapeGFM(text) {
    return text.replace(/&/g, '&amp;') // HTML
               .replace(/</g, '&lt;') // HTML
               .replace(/>/g, '&gt;') // blockquote
               .replace(/([:@=])/g, '$1\u200b') // emoji, @mention, headings
               .replace(/([\\`\*_\{\}\[\]\(\)#\+\-\.!\~\|])/g, '\\$1'); // other formatting
  }

  function getBody(url, selectionText) {
    let quotedText = selectionText;
    if (quotedText.length > 1000) {
      quotedText = quotedText.substring(0, 997) + '...';
    }

    quotedText = escapeGFM(quotedText).replace(/\r/g, '').replace(/\n/g, '\n> ');
    if (quotedText.length > 0) {
      quotedText = '> ' + quotedText;
    }

    return url + '\n\n' + quotedText;
  }

  function getTitle(selectionText) {
    let title = selectionText.replace(/\n/g, ' ');
    if (title.length > 50) {
      title = title.substring(0, 47) + '...';
    }

    if (title.length > 0) {
      title = '"' + title + '"';
    }

    return titlePrefix + title;
  }

  function getURLToReport(selection) {
    let url = specURL;

    const node = getBestNodeToReport(selection);
    if (node) {
      url = url.split('#')[0] + '#' + node.id;
    }

    return url;
  }

  function getBestNodeToReport(selection) {
    let node = null;

    if (selection.anchorNode) {
      node = selection.anchorNode;

      if (selection.focusNode && selection.focusNode.compareDocumentPosition) {
        const compare = selection.focusNode.compareDocumentPosition(selection.anchorNode);
        if (compare & Node.DOCUMENT_POSITION_FOLLOWING || compare & Node.DOCUMENT_POSITION_CONTAINED_BY) {
          node = selection.focusNode;
        }
      }
    }

    while (node && !node.id) {
      node = node.previousSibling || node.parentNode;
    }

    return node;
  }
}());
