#!/usr/bin/env python

from __future__ import print_function
import argparse
import markdown
from mdx_partial_gfm import PartialGithubFlavoredMarkdownExtension
import re
import string


def parse_arguments():
    parser = argparse.ArgumentParser(description="Convert a Markdown-formatted WHATWG policy to HTML suitable for publishing on whatwg.org")
    parser.add_argument('policy', metavar='POLICY', type=argparse.FileType(), help="The markdown policy document to convert")
    parser.add_argument('template', metavar='TEMPLATE', type=argparse.FileType(), help="A template to add appropriate boilerplate to the policy")
    parser.add_argument('link_mapping', metavar='MAPPING', type=argparse.FileType(), help="File defining link mappings")

    args = parser.parse_args()

    return (args.policy, args.template, args.link_mapping)


def lower_headers(policy_markdown):
    return re.sub(r'^#', '##', policy_markdown, flags=re.MULTILINE)


def apply_link_mapping(policy_markdown, link_mapping):
    mapping_pairs = [line.split('=',1) for line in link_mapping.split("\n") if len(line) > 0]
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
    header_text = line.lstrip('#')
    header_level = len(line) - len(header_text)

    if header_level <= 2:
        return line

    header_text = header_text.lstrip(' ')
    header_id = header_text_to_id(header_text)

    return '<h{0} id="{1}">{2}<a class="self-link" href="#{1}"></a></h{0}>'.format(header_level, header_id, header_text)


def add_header_anchors(policy_markdown):
    return str.join('\n', [add_one_header_anchor(line) for line in policy_markdown.split('\n')])


def rewrite_defs(policy_markdown):
    return re.sub(r'<a id=([^>]*)>[*][*]([^*]*)[*][*]</a>', '<dfn id=\\1>\\2</dfn>', policy_markdown)


def fix_nested_lists(policy_markdown):
    return re.sub(r'^   1[.]', '    1.', policy_markdown, flags=re.MULTILINE)


def avoid_link_false_positives(policy_markdown):
    return re.sub(r'[]] [(]', '] \\(', policy_markdown)


def preprocess_markdown(policy_markdown, link_mapping):
    result = lower_headers(policy_markdown)
    result = apply_link_mapping(result, link_mapping)
    result = add_header_anchors(result)
    result = rewrite_defs(result)
    result = fix_nested_lists(result)
    result = avoid_link_false_positives(result)

    return result


def markdown_title(policy_markdown):
    for line in policy_markdown.split('\n'):
        if line.startswith("#"):
            title = line.lstrip("# ")
            tile = "WHATWG " + title if "WHATWG" not in title else title
            replacement_line = re.sub(r'^# WHATWG ', '# ', line)
            policy_markdown = policy_markdown.replace(line, replacement_line)

            return (title, policy_markdown)

    return ("WHATWG Policies", policy_markdown)


def main():
    (policy_file, template_file, link_mapping_file) = parse_arguments()
    policy_markdown = policy_file.read().decode('utf-8')
    template = template_file.read().decode('utf-8')
    link_mapping = link_mapping_file.read().decode('utf-8')

    (title, policy_markdown) = markdown_title(policy_markdown)
    preprocessed_policy_markdown = preprocess_markdown(policy_markdown, link_mapping)

    policy_html = markdown.markdown(preprocessed_policy_markdown, extensions=[PartialGithubFlavoredMarkdownExtension()])

    final_policy_html = template.replace("@POLICY_GOES_HERE@", policy_html)
    final_policy_html = final_policy_html.replace("@TITLE_GOES_HERE@", title)

    print(final_policy_html.encode('utf-8'))

main()
