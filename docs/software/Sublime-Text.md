# Sublime Text 3

## Setting

```json
{
    //"color_scheme": "Packages/MarkdownEditing/MarkdownEditor-Dark.tmTheme",
    //"font_size": 8,
    "word_wrap": true,
    "wrap_width": 80,
    "fade_fold_buttons": false,
    "bold_folder_labels": true,
    "trim_trailing_white_space_on_save": true,
    "draw_white_space": "all",
    "rulers": [80, 100, 120],
    "enable_table_editor": true,
    "tab_size": 4,
    "translate_tabs_to_spaces": true,
    "word_separators": "./\\()\"'-:,.;<>~!@#$%^&*|+=[]{}`~?。、（）“”‘’：，；《》！【】『』",
}

{
    "detect_indentation": false,
    // "font_face": "新宋体",
    // "font_face": "Ubuntu Mono",
    "font_face":"YaHei Consolas Hybrid",
    "font_size": 10.0,
    "font_options": ["no_bold"],
    "font_options": ["directwrite"],
    "highlight_line": true,
    "http_proxy": "http://127.0.0.1:3218",
    "https_proxy": "http://127.0.0.1:3218",
    "update_check": false,
}
```

- http://sublime-text-unofficial-documentation.readthedocs.org/en/latest/reference/settings.html

## Themes

- https://github.com/jonschlinkert/sublime-monokai-extended
- https://github.com/thinkpixellab/flatland

You can download a copy of the original theme here and save it to `{SUBLIME TEXT FOLDER}/Packages/User/Color Schemes/`

## Packages

### PackageControl

- https://packagecontrol.io/installation
- https://packagecontrol.io/docs/settings
- http://www.laurii.info/2013/08/sublime-text-3-install-package-controller-proxy/

```
importurllib.request,os
pf='Package Control.sublime-package'
ipp=sublime.installed_packages_path()
urllib.request.install_opener(
    urllib.request.build_opener(
        urllib.request.ProxyHandler(
            {"http":"http://[user]:[password]@[proxy_IP]:[proxy_port]"}
        )
    )
)
open(os.path.join(ipp,pf),'wb').write(
    urllib.request.urlopen(
        'http://sublime.wbond.net/'+pf.replace(' ','%20')
    ).read()
)
```

``` urllib.request.build_opener( urllib.request.ProxyHandler({"http":"http://127.0.0.1:3218"}))

// @ == %40
```

```
// Preferences > Package Settings > Package Control > Settings – User
{
    "debug":true,
    "timeout":120,
    //"proxy_username":"pass",
    //"proxy_password":"user"
    "http_proxy":"127.0.0.1:3218",
    "https_proxy":"127.0.0.1:3218"
}
```

### MarkdownEditing

- Ctrl-Shift-B  Bold
- Ctrl-Shift-I  Italic
- Ctrl-1...6  Heading.
- Ctrl-Shift-6  Footnote
- Ctrl-Shift-M  Lint.
- Ctrl-Win-K  Inserts a standard inline link.

```
{
    "enable_table_editor": true,
    "draw_centered": false,
    "word_wrap": false,
}
```
### Monokai Extended

Good markdown syntax color scheme.

### SmartMarkdown

https://github.com/demon386/SmartMarkdown

Support heading fold and unfold.

### Other Packages
- Table Editor
  https://github.com/vkocubinsky/SublimeTableEditor
- git
  https://sublime.wbond.net/packages/GitGutter
- PackageResourceViewer
- GBK Encoding Support
- Markdown Extended

## Basic

Sublime Text can be reverted to a freshly installed state by removing your data folder. Depending on your operating system, this folder is located in:

    OS X: ~/Library/Application Support/Sublime Text 3
    Windows: %APPDATA%\Sublime Text 3
    Linux: ~/.config/sublime-text-3

## Related

- https://github.com/aziz/tmTheme-Editor
- color code
  - http://en.wikipedia.org/wiki/Web_colors
  - http://www.eubank-web.com/William/Webmaster/color.htm
- http://www.sitepoint.com/sublime-text-perfect-blogging-6-ways/
