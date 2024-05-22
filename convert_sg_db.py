#!/usr/bin/env python

import json
from convert_policy import markdown, obtain_link_mapping


def create_biblio(db):
    biblio = {}

    for workstream in db["workstreams"]:
        for standard in workstream["standards"]:
            reference, contents = standard_or_idea_to_biblio(standard)
            contents["title"] += " Standard"
            biblio[reference] = contents

    for idea in db["ideas"]:
        reference, contents = standard_or_idea_to_biblio(idea)
        contents["status"] = "Living Idea"
        biblio[reference] = contents

    for biblio_item in db["biblio"]:
        reference, contents = biblio_item_to_biblio(biblio_item)
        biblio[reference] = contents

    string = json.dumps(biblio, ensure_ascii=False, allow_nan=False, sort_keys=True, indent=2)
    return string + "\n"

def standard_or_idea_to_biblio(document):
    return (document["reference"], {
        "authors": [author_to_biblio(author) for author in document["authors"]],
        "href": document["href"],
        "title": document["name"]
    })

def biblio_item_to_biblio(item):
    contents = {
        "href": item["href"],
        "title": item["title"]
    }
    if len(item["authors"]):
        contents["authors"] = [author_to_biblio(author) for author in item["authors"]]
    if "obsoletedBy" in item:
        contents["obsoletedBy"] = item["obsoletedBy"]
    return (item["reference"], contents)

def author_to_biblio(person):
    return person["name"]


def create_spec_whatwg_org(db, template):
    content = "<p>The WHATWG works on a number of technologies that are fundamental parts of the web platform. They are organised somewhat arbitrarily based on the preferences of those editing the standard for those technologies.</p>\n\n"
    content += "<dl>"
    standards = []
    for workstream in db["workstreams"]:
        for standard in workstream["standards"]:
            standards.append(standard)
    standards.sort(key=lambda standard: standard["name"])
    for standard in standards:
        content += standard_or_idea_to_html(standard)
    content += "</dl>\n\n<p>The WHATWG also works on a <a href=\"https://idea.whatwg.org/\">number of ideas</a> that aspire to become standards one day.</p>\n\n"

    template = template.replace("<a href=\"https://spec.whatwg.org/\">Standards</a>", "<a>Standards</a>")
    return wrap_in_site_template(template, "Standards", content)

def create_idea_whatwg_org(db, template):
    content = "<p>The WHATWG works on a number of ideas that aspire to become web platform standards.</p>\n\n"
    content += "<dl>"
    for idea in db["ideas"]:
        content += standard_or_idea_to_html(idea)
    content += "</dl>\n\n"

    return wrap_in_site_template(template, "Ideas", content)

def standard_or_idea_to_html(document):
    x_output = ""
    # Optional as ideas currently do not have X accounts
    if "twitter" in document:
        x_output = " (<a href=\"https://x.com/{0}\">@{1}</a>)".format(document["twitter"], document["twitter"])
    output = "\n <dt><a href=\"{0}\">{1}</a>{2}</dt>".format(document["href"], document["name"], x_output)
    return output + "\n <dd>{}</dd>\n".format(markdown(document["description"])[:-1]) # Strip trailing \n


def create_workstreams(db, template):
    introduction = open("sg/Workstreams Introduction.md", "r", encoding="utf-8").read()
    introduction = introduction.replace("<!-- This ends up being included at https://whatwg.org/workstreams -->\n", "")
    content = markdown(introduction, obtain_link_mapping())
    for workstream in db["workstreams"]:
        content += '\n<h2 id="{}">{}</h2>'.format(workstream["id"], workstream["name"])
        content += """\n<dl class="compact">"""
        content += "\n <div>"
        content += "\n  <dt>Scope</dt>"
        content += "\n  <dd>{}</dd>".format(markdown(workstream["scope"])[3:-5]) # Strip leading <p> and trailing </p>\n
        content += "\n </div>"
        content += "\n <div>"
        content += "\n  <dt>Editor{}</dt>".format("" if len(workstream["editors"]) == 1 else "s")
        for editor in workstream["editors"]:
            content += """\n  <dd>{0}, <a href="mailto:{1}">{1}</a></dd>""".format(editor["name"], editor["email"])
        content += "\n </div>"
        content += "\n <div>"
        content += "\n  <dt>Standard{}</dt>".format("" if len(workstream["standards"]) == 1 else "s")
        for standard in workstream["standards"]:
            content += """\n  <dd><a href="{0}">{1}</a></dd>""".format(standard["href"], standard["name"])
        content += "\n </div>"
        content += "\n</dl>"

    return wrap_in_site_template(template, "Workstreams", content)


def wrap_in_site_template(template, title, content):
    output = template.replace("@TITLE_GOES_HERE@", title)
    return output.replace("@CONTENT_GOES_HERE@", content)

def main():
    template = open("site-template.html", "r", encoding="utf-8").read()
    copyright = """<footer>
 <p><small>Copyright © WHATWG (Apple, Google, Mozilla, Microsoft). This work is licensed under a <a rel="license" href="https://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International License</a>.</small></p>
</footer>"""
    template = template.replace("@CONTENT_GOES_HERE@", "@CONTENT_GOES_HERE@" + copyright)
    db = json.load(open("sg/db.json", "r", encoding="utf-8"))

    for filename, content in [
      ("resources.whatwg.org/biblio.json", create_biblio(db)),
      ("spec.whatwg.org/index.html", create_spec_whatwg_org(db, template)),
      ("idea.whatwg.org/index.html", create_idea_whatwg_org(db, template)),
      ("whatwg.org/workstreams", create_workstreams(db, template))
    ]:
        open(filename, "w", encoding="utf-8").write(content)

main()
