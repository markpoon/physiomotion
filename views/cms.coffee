$ ->
  window.App = {}
  App.editting = false
  App.path=->
    path = window.location.pathname.replace("/", "")
    if !path then path = "index"
    return path

  get_page_index_ajax=()->
    $.ajax "/pages/",
      type:"GET"
      dataType:"json"
      async:false
      success:(data, status, jqxhr)->
        make_menus data
      error:(data, status, jqxhr)->
        alert("there was a problem loading menus")

  post_page_ajax= ->
    $.ajax "/pages/",
      type:"POST"
      dataType:"json"
      async:false
      success:(data, status, jqxhr)->
        make_menus data
      error:(data, status, jqxhr)->
        alert("could not make a new page for some reason")

  post_section_ajax= ->
    $.ajax "/pages/#{App.path()}",
      type:"POST"
      dataType:"json"
      async:false
      success:(data, status, jqxhr)->
        get_page_ajax(App.path())
        for_each_markdown_region get_markdown_ajax
      error:(data, status, jqxhr)->
        alert("could not make a new section for some reason")

  get_page_ajax=(path)->
    $.ajax "/pages/#{path}",
      type:"GET"
      dataType:"json"
      async:false
      success:(data, status, jqxhr)->
        make_markdown_regions(data)
      error:(data, status, jqxhr)->
        alert("there was no markdown regions")

  get_markdown_ajax=(markdown)->
    $.ajax "/pages/#{App.path()}/#{markdown.id}",
      type:"GET"
      dataType:"json"
      async:false
      success:(data, status, jqxhr)->
        display_html(data, markdown)
      error:(data, status, jqxhr)->
        alert("error loading markdown")

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
        error:(data, status, jqxhr)->
    else
      alert "no password present"

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
        App.editting = false
        markdown.classList.remove "edited"
        markdown.classList.add "editable"
      error:(data, status, jqxhr)->
        alert("unable to PUT")

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

  make_menus=(data)->
    $(".menuitem").remove()
    menu = $(".dropdown-menu")
    for menuitem in data.reverse()
      title = menuitem.title.replace(/_/gi, ' ')
      menu.prepend("<li class=\"menuitem\"><a href=\"#{menuitem.title}\">#{title}<i style=\"float:right;\" class=\"fa #{menuitem.icon}\"></i></li>")

  make_markdown_regions=(regions)->
    content = $(".md")
    for region in regions
      content.append("<div class=\"row\"><div id=\"#{region._id}\" class=\"mdc col-sm-12 col-md-10 col-md-offset-1 col-lg-8 col-lg-offset-2\"></div></div>")

  for_each_markdown_region=(func)->
    func(markdown) for markdown in $(".mdc")

  display_html=(content, markdown)->
    for targets in $("#"+markdown.id)
      targets.innerHTML = content

  display_text=(content, markdown)->
    for targets in $("#"+markdown.id)
      targets.innerText = content

  show_password_entry= ->
    $("#loginmodal").modal('toggle')

  set_editing_style=(markdown)->
    markdown.classList.add "editable"
    markdown.contentEditable= "true"
    markdown.onfocus= ->
      @classList.remove "editable"
      @classList.add "editing"
      get_plaintext_ajax markdown

    markdown.onblur= ->
      if App.editting == false
        App.editting = true
        @classList.remove "editing"
        @classList.add "edited"
        put_plaintext_ajax markdown

  remove_editing_style=(markdown)->
    markdown.classList.remove "editable"
    markdown.classList.remove "editting"
    markdown.classList.remove "editted"
    markdown.contentEditable= "false"
    markdown.removeAttribute "onblur"
    markdown.removeAttribute "onfocus"

  set_editing_interface= ->
    $("#edit").text "Done Editing"
    $(".dropdown-menu").append("<li><a id=\"createpage\" href=\"#\">Add Page</li>")
    $("#topinterface").prepend('<div class="row"><div id="pagecontrols" class="col-sm-12 col-md-10 col-md-offset-1 col-lg-8 col-lg-offset-2"><button style="width:100%" id="tobottom" type="button" class="btn btn-lg">Scroll To The Bottom</button></div></div>')
    $("#bottominterface").append('<div class="row"><div id="pagecontrols" class="col-sm-12 col-md-10 col-md-offset-1 col-lg-8 col-lg-offset-2"><button style="width:100%" id="createsection" type="button" class="btn btn-lg btn-success">Add Another Section</button></div></div>')
    $(".nav").off "click", "#edit"
    $(".nav").on "click", "#edit", ->
      remove_editing_interface()

  $(document).on "click", "#tobottom", ->
    $("html, body").scrollTop $(document).height()

  $(document).on "click", "#createsection", ->
    create_section()

  $(".dropdown-menu").on "click", "#createpage", ->
    create_page()

  create_page= ->
    post_page_ajax()

  create_section= ->
    post_section_ajax()

  remove_editing_interface= ->
    $("#edit").text "Edit"
    $(".nav").off "click", "#edit"
    $("#createpage").remove()
    $("#pagecontrols").remove()
    $(".nav").on "click", "#edit", ->
      show_password_entry()
    for_each_markdown_region get_markdown_ajax
    for_each_markdown_region remove_editing_style

  $("#loginmodal").on "shown.bs.modal", (e) ->
    $("#passwordField").focus()

  $("#passwordField").on "keypress", (e) ->
    if e.keyCode == 13
      $("#login").click()

  $("#login").click ->
    App.password = $("#passwordField").val()
    $("#loginmodal").modal 'toggle'
    if (for_each_markdown_region get_plaintext_ajax)
      set_editing_interface()

  get_page_index_ajax()
  get_page_ajax(App.path())
  for_each_markdown_region get_markdown_ajax
  remove_editing_interface()
