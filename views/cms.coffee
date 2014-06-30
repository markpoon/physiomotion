$(document).ready ->
  window.App = {}
  App.path=->
    path = window.location.pathname.replace("/", "")
    if !path then path = "index"

  get_page_index_ajax=(page)->
    $.ajax "/pages/",
      type:"GET"
      dataType:"json"
      async:false
      success:(data, status, jqxhr)->
        make_menus data
        null
      error:(data, status, jqxhr)->
        alert("menu problem")
        null
    null

  get_page_ajax=(path)->
    $.ajax "/pages/#{path}",
      type:"GET"
      dataType:"json"
      async:false
      success:(data, status, jqxhr)->
        make_markdown_regions(data)
        null
      error:(data, status, jqxhr)->
        alert("there was no markdown regions")
        null
    null

  get_markdown_ajax=(markdown)->
    $.ajax "/pages/#{App.path()}/#{markdown.id}",
      type:"GET"
      dataType:"json"
      async:false
      success:(data, status, jqxhr)->
        display_html(data, markdown)
        null
      error:(data, status, jqxhr)->
        alert("error loading markdown")
        null
    null

  get_plaintext_ajax=(markdown)->
    if App.password
      $.ajax "/pages/#{App.path()}/#{markdown.id}/raw",
        type:"GET"
        dataType:"json"
        async:false
        username:'user'
        password:App.password
        success:(data, status, jqxhr)->
          for_each_markdown_region (set_editing_style)
          display_html(data, markdown)
          null
        error:(data, status, jqxhr)->
          alert "error loading markdown"
          null
    else
      alert "no password present"
    null

  put_plaintext_ajax=(markdown)->
    $.ajax "/pages/#{App.path()}/#{markdown.id}",
      type:"PUT"
      dataType:"json"
      async:false
      data:
        markdown:
          markdown.innerHTML
      success:(data, status, jqxhr)->
        display_html(data, markdown)
        null
      error:(data, status, jqxhr)->
        alert("unable to PUT")
        null

  post_plaintext_ajax=(markdown)->
    $.ajax "/pages/#{markdown.id}",
      type:"PUT"
      dataType:"json"
      async:false
      data:
        markdown:
          markdown.innerHTML
      success:(data, status, jqxhr)->
        display_html(data,markdown)
      error:(data, status, jqxhr)->
        alert("error loading markdown")
    null

  make_menus=(data)->
    menu = $(".dropdown-menu")
    for menuitem in data.reverse()
      title = menuitem.title.replace(/_/gi, ' ')
      menu.prepend("<li><a href=\"#{menuitem.title}\">
                   <i class=\"fa #{menuitem.icon}\"></i> #{title}</a></li>")

  make_markdown_regions=(regions)->
    content = $(".md")
    for region in regions
      content.append("<div class=\"row\"><div id=\"#{region.title}\" class=\"mdc col-sm-12 col-md-10 col-md-offset-1 col-lg-8 col-lg-offset-2\"></div></div>")

  for_each_markdown_region=(func)->
    func(markdown) for markdown in $(".mdc")
    null

  display_html=(content, markdown)->
    for targets in $("#"+markdown.id)
      targets.innerHTML = content
    null

  set_editing_style=(markdown)->
    $("#edit").text("Finish Editing")
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
      markdown.contentEditable= "false"
      put_plaintext_ajax markdown
      null
    null

  toggle_edit_ui= ->
    $("#loginmodal").modal('toggle')
    null

  window.toggle_edit_ui = toggle_edit_ui

  $("#loginmodal").on "shown.bs.modal", (e) ->
    $("#passwordField").focus()
    null

  $("#passwordField").on "keypress", (e) ->
    if e.keyCode == 13
      $("#login").click()
    null

  $("#login").click ->
    App.password = $("#passwordField").val()
    $("#loginmodal").modal 'toggle'
    for_each_markdown_region set_editing_style
    for_each_markdown_region get_plaintext_ajax
    null

  get_page_index_ajax()
  get_page_ajax(App.path())
  for_each_markdown_region get_markdown_ajax
