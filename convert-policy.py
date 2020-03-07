#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import codecs
import commonmark
import re


def lower_headers(policy_markdown):
    return re.sub(r'^#', '##', policy_markdown, flags=re.MULTILINE)


def parse_link_mapping(link_mapping):
    return [line.split('=',1) for line in link_mapping.split("\n") if len(line) > 0]


def apply_link_mapping(policy_markdown, mapping_pairs):
    for mapping in mapping_pairs:
        policy_markdown = policy_markdown.replace(mapping[0], mapping[1])

    return policy_markdown


def ascii_lower(str):
    return "".join([char.lower() if char >= 'A' and char <= 'Z' else char for char in str])


def header_text_to_id(header_text):
    punctuation_regexp = r'[^\w\- ]'
    header_id = ascii_lower(header_text)
    header_id = re.sub(punctuation_regexp, '', header_id)
    header_id = re.sub(' ', '-', header_id)

    return header_id


def add_one_header_anchor(line):
    search = re.search(r'<h([3-6])>(.+)</h([3-6])>', line)
    if not search:
        return line

    header_level = search.group(1)
    header_text = search.group(2)
    header_id = header_text_to_id(header_text)

    return '<h{0} id="{1}">{2}<a class="self-link" href="#{1}"></a></h{0}>'.format(header_level, header_id, header_text)


def add_header_anchors(policy_markdown):
    return str.join('\n', [add_one_header_anchor(line) for line in policy_markdown.split('\n')])


def rewrite_defs(policy_markdown):
    return re.sub(r'<a id=([^>]*)>[*][*]([^*]*)[*][*]</a>', '<dfn id=\\1>\\2</dfn>', policy_markdown)


def avoid_link_false_positives(policy_markdown):
    return re.sub(r'[]] [(]', '] \\(', policy_markdown)


def preprocess_markdown(policy_markdown, mapping_pairs):
    result = lower_headers(policy_markdown)
    result = apply_link_mapping(result, mapping_pairs)
    result = rewrite_defs(result)
    result = avoid_link_false_positives(result)

    return result


def markdown_title(policy_markdown):
    for line in policy_markdown.split('\n'):
        if line.startswith("# WHATWG "):
            title = line[len("# WHATWG "):]
            policy_markdown = policy_markdown.replace(line, "")

            return (title, policy_markdown)

    return ("Policies", policy_markdown)


def main():
    link_mapping_pairs = parse_link_mapping(codecs.open("sg/policy-link-mapping.txt", "r", encoding="utf-8").read())
    template = codecs.open("policy-template.html", "r", encoding="utf-8").read()
    for resource, link in link_mapping_pairs:
        if link.startswith("https:"):
            continue

        policy_markdown = codecs.open("sg" + resource[1:].replace("%20", " "), "r", encoding="utf-8").read()

        (title, policy_markdown) = markdown_title(policy_markdown)
        preprocessed_policy_markdown = preprocess_markdown(policy_markdown, link_mapping_pairs)

        policy_html = commonmark.commonmark(preprocessed_policy_markdown)
        policy_html = policy_html.replace("&quot;", "\"")

        final_policy_html = template.replace("@POLICY_GOES_HERE@", policy_html)
        final_policy_html = final_policy_html.replace("@TITLE_GOES_HERE@", title)
        final_policy_html = add_header_anchors(final_policy_html)

        codecs.open("whatwg.org/" + link, "w", encoding="utf-8").write(final_policy_html)

main()
