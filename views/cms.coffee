for_each_markdown_region=(func)->
  func(markdown) for markdown in $(".md")
  null

display_html=(id, data)->
  for targets in $("#"+id)
    targets.innerHTML = data
  null

get_markdown_ajax=(markdown)->
  $.ajax "/md/#{markdown.id}",
    type:"GET"
    dataType:"html"
    success:(data, status, jqxhr)->
      display_html(markdown.id, data)
      null
    error:(data, status, jqxhr)->
      alert("error loading markdown")
      null
  null

get_plaintext_ajax=(markdown)->
  $.ajax "/markdown/#{markdown.id}",
    type:"GET"
    dataType:"html"
    success:(data, status, jqxhr)->
      display_html(markdown.id, data)
    error:(data, status, jqxhr)->
      alert("error loading markdown")
      null
  null

post_plaintext_ajax=(markdown)->
  $.ajax "/markdown/#{markdown.id}",
    type:"POST"
    dataType:"text"
    data:
      markdown:
        markdown.innerText
    success:(data, status, jqxhr)->
      display_html(markdown.id, data)
    error:(data, status, jqxhr)->
      alert("error loading markdown")
      null

set_editing_style=(markdown)->
  markdown.classList.add "editing"
  markdown.contentEditable= "true"
  markdown.onfocus= ->
    @classList.remove "editing"
    @classList.add "pre"
    get_plaintext_ajax(markdown)
    null
  markdown.onblur= ->
    @classList.add "editing"
    @classList.remove "pre"
    post_plaintext_ajax markdown
  null

toggle_edit_ui= ->
  $.get "/login"
  for_each_markdown_region (set_editing_style)
  null

logout= ->
  $.get "/logout"

window.toggle_edit_ui = toggle_edit_ui
window.logout = logout

$(document).ready ->
  for_each_markdown_region (get_markdown_ajax)
  null
