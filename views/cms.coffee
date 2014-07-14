$(document).ready ->
  window.App = {}
  App.saving = false
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
      $.ajax "/pages/#{App.path()}/#{markdown.id}/plaintext",
        type:"GET"
        dataType:"json"
        async:false
        username:'user'
        password:App.password
        success:(data, status, jqxhr)->
          set_editing_style markdown
          display_text(data, markdown)
          null
        error:(data, status, jqxhr)->
          null
    else
      alert "no password present"
    null

  put_plaintext_ajax=(markdown)->
    $.ajax "/pages/#{App.path()}/#{markdown.id}",
      type:"PUT"
      dataType:"json"
      async:false
      username:'user'
      password:App.password
      data:
        markdown:
          markdown.innerText
      success:(data, status, jqxhr)->
        display_text(data, markdown)
        App.saving = false
        markdown.classList.remove "edited"
        markdown.classList.add "editable"
        null
      error:(data, status, jqxhr)->
        alert("unable to PUT")
        null

  post_plaintext_ajax=(markdown)->
    $.ajax "/pages/#{markdown.id}",
      type:"POST"
      dataType:"json"
      async:false
      username:'user'
      password:App.password
      data:
        markdown:
          markdown.innerHTML
      success:(data, status, jqxhr)->
        display_text(data,markdown)
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

  display_text=(content, markdown)->
    for targets in $("#"+markdown.id)
      targets.innerText = content
    null

  set_editing_style=(markdown)->
    markdown.classList.add "editable"
    markdown.contentEditable= "true"
    markdown.onfocus= ->
      @classList.remove "editable"
      @classList.add "editing"
      get_plaintext_ajax markdown
      null

    markdown.onblur= ->
      if App.saving == false
        App.saving = true
        @classList.remove "editing"
        @classList.add "edited"
        put_plaintext_ajax markdown
      null
    null

  remove_editing_style=(markdown)->
    markdown.classList.remove "editable"
    markdown.contentEditable= "false"
    markdown.onblur= ->
      null
    markdown.onfocus= ->
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
    for_each_markdown_region get_plaintext_ajax
    $("#edit").text "Finish"
    $("#edit").click ->
      $("#edit").text "Edit"
      for_each_markdown_region remove_editing_style
      for_each_markdown_region get_markdown_ajax
      $("#edit").click ->
        toggle_edit_ui()
        null
    null

  $("#edit").click ->
    toggle_edit_ui()
    null

  get_page_index_ajax()
  get_page_ajax(App.path())
  for_each_markdown_region get_markdown_ajax
