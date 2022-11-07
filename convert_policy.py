#!/usr/bin/env python

import commonmark
import re


def obtain_link_mapping():
    link_mapping = open("sg/policy-link-mapping.txt", "r", encoding="utf-8").read()
    return [line.split('=',1) for line in link_mapping.split("\n") if len(line) > 0]


def apply_link_mapping(policy_markdown, mapping_pairs):
    for mapping in mapping_pairs:
        policy_markdown = policy_markdown.replace(mapping[0], mapping[1])

    return policy_markdown


def ascii_lower(str):
    return "".join([char.lower() if char >= 'A' and char <= 'Z' else char for char in str])


def header_text_to_id(header_text):
    header_text = header_text.replace("&quot;", "")
    punctuation_regexp = r'[^\w\- ]'
    header_id = ascii_lower(header_text)
    header_id = re.sub(punctuation_regexp, '', header_id)
    header_id = re.sub(' ', '-', header_id)

    if header_id == "anchor-permanence":
        return "anchors"

    return header_id


def adjust_header(line):
    search = re.search(r'<h([2-6])>(.+)</h([2-6])>', line)
    if not search:
        return line

    header_level = search.group(1)
    header_text = search.group(2)
    header_id = header_text_to_id(header_text)

    return '<h{0} id="{1}">{2}<a class="self-link" href="#{1}"></a></h{0}>'.format(header_level, header_id, header_text)


def adjust_headers(policy_markdown):
    return str.join('\n', [adjust_header(line) for line in policy_markdown.split('\n')])


def rewrite_defs(policy_markdown):
    return re.sub(r'<a id=([^>]*)>[*][*]([^*]*)[*][*]</a>', '<dfn id=\\1>\\2</dfn>', policy_markdown)


def markdown(policy_markdown, mapping_pairs = []):
    result = apply_link_mapping(policy_markdown, mapping_pairs)
    result = rewrite_defs(result)
    result = commonmark.commonmark(result)

    return result


def postprocess_html(policy_html, template, title):
    result = adjust_headers(policy_html)
    result = template.replace("@CONTENT_GOES_HERE@", result)
    result = result.replace("@TITLE_GOES_HERE@", title)
    result = result.replace("<p>EXAMPLE: ", "<p class=\"example\">")
    result = result.replace("<p>NOTE: ", "<p class=\"note\">")
    result = result.replace("<hr>\n<footer>", "<footer>")
    result = result.replace("""<a href="https://creativecommons.org/licenses/by/4.0/">""", """<a rel="license" href="https://creativecommons.org/licenses/by/4.0/">""")

    return result


def markdown_title(policy_markdown):
    for line in policy_markdown.split('\n'):
        if line.startswith("# WHATWG "):
            title = line[len("# WHATWG "):]
            policy_markdown = policy_markdown.replace(line, "")

            return (title, policy_markdown)

    assert False, "Markdown does not contain a line starting with # WHATWG "


def main():
    link_mapping_pairs = obtain_link_mapping()
    template = open("site-template.html", "r", encoding="utf-8").read()
    for resource, link in link_mapping_pairs:
        if link.startswith("https:"):
            continue

        policy_markdown = open("sg" + resource[1:].replace("%20", " "), "r", encoding="utf-8").read()

        (title, policy_markdown) = markdown_title(policy_markdown)

        policy_html = markdown(policy_markdown, link_mapping_pairs)

        postprocessed_policy_html = postprocess_html(policy_html, template, title)

        open("whatwg.org/" + link, "w", encoding="utf-8").write(postprocessed_policy_html)

if __name__ == "__main__":
    main()
