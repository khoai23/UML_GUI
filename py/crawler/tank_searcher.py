import requests
import re, io
import json

category_regex = re.compile(r"en\/Category:([\w\d_-]+)")
tank_regex = re.compile(r"en\/Tank:([\w\d_-]+)")
title_regex = re.compile(r"<title>(.+?)<\/title>")

category_format = r"https://wiki.wargaming.net/en/Category:{:s}"
tank_format = r"https://wiki.wargaming.net/en/Tank:{:s}"

nation_link = r"https://wiki.wargaming.net/en/Category:Tanks_by_nation"
tier_link = r"https://wiki.wargaming.net/en/Category:Tanks_by_tier"
class_link = r"https://wiki.wargaming.net/en/Category:Tanks_by_type"

def get_text(link, session=requests):
    req = session.get(link)
    data = req.text
    req.close()
    return data

def clean_set(list_keywords, ignore={"tanks_by_nation", "tanks_by_tier", "tanks_by_type", "tanks", "nations"}):
    return {k for k in list_keywords if k.lower() not in ignore}

def get_display_name(code, session=requests):
    print("Get display name for {:s}".format(code))
    req = session.get(tank_format.format(code))
    data = req.text
    #print(code, data)
    req.close()
    title = title_regex.search(data).group(1)
    return title.rsplit("-", 1)[0].strip()

#print(get_text(nation_link))
#raise ValueError

with requests.session() as sess:
    nation_categories = clean_set(category_regex.findall(get_text(nation_link, session=sess)))
    tier_categories   = clean_set(category_regex.findall(get_text(tier_link, session=sess)))
    class_categories  = clean_set(category_regex.findall(get_text(class_link, session=sess)))
    
    nation_dict = {}
    for n in nation_categories:
        print("Searching {:s}".format(n))
        nlink = category_format.format(n)
        nation_dict[n] = tank_regex.findall(get_text(nlink, session=sess))
        
    tier_dict = {}
    for t in tier_categories:
        print("Searching {:s}".format(t))
        tlink = category_format.format(t)
        tier_dict[t.replace("_Tanks", "")] = tank_regex.findall(get_text(tlink, session=sess))
        
    class_dict = {}
    for c in class_categories:
        print("Searching {:s}".format(c))
        clink = category_format.format(c)
        class_dict[c] = tank_regex.findall(get_text(clink, session=sess))
    
    all_names = {k: get_display_name(k, session=sess) for cat in class_dict.values() for k in cat}

print([nation_dict, tier_dict, class_dict, all_names])
with io.open("tank_data.json", "w") as jf:
    json.dump([nation_dict, tier_dict, class_dict, all_names], jf, indent=2)