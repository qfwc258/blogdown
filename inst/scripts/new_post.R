local({
  tags = htmltools::tags
  txt_input = function(..., width = '100%') shiny::textInput(..., width = width)
  sel_input = function(...) shiny::selectizeInput(
    ..., width = '98%', multiple = TRUE, options = list(create = TRUE)
  )
  meta = blogdown:::collect_yaml()
  shiny::runGadget(
    miniUI::miniPage(miniUI::miniContentPanel(
      txt_input('title', 'Title', placeholder = 'Post Title'),
      shiny::fillRow(
        txt_input('author', 'Author', getOption('blogdown.author', ''), width = '98%'),
        shiny::dateInput('date', 'Date', Sys.Date(), width = '98%'),
        txt_input(
          'subdir', 'Subdirectory', getOption('blogdown.subdir', 'post'),
          '(optional)', width = '98%'
        ),
        height = '70px'
      ),
      shiny::fillRow(
        sel_input('cat', 'Categories', meta$categories),
        sel_input('tag', 'Tags', meta$tags),
        shiny::selectInput(
          'kind', 'Archetype', width = '98%',
          choices = unique(c('default', xfun::sans_ext(dir('archetypes', '\\.md$'))))
        ),
        height = '70px'
      ),
      shiny::fillRow(
        txt_input('file', 'Filename', '', 'automatically generated (edit if you want)'),
        height = '70px'
      ),
      shiny::fillRow(txt_input('slug', 'Slug', '', '(optional)'), height = '70px'),
      shiny::fillRow(
        shiny::radioButtons(
          'format', 'Format', inline = TRUE,
          c('Markdown' = '.md', 'R Markdown (.Rmd)' = '.Rmd', 'R Markdown (.Rmarkdown)' = '.Rmarkdown'),
          selected = getOption('blogdown.ext', '.md')
        ),
        height = '70px'
      ),
      miniUI::gadgetTitleBar(NULL)
    )),
    server = function(input, output, session) {
      empty_title = shiny::reactive(grepl('^\\s*$', input$title))
      shiny::observe({
        if (!empty_title()) shiny::updateTextInput(
          session, 'file', value = blogdown:::post_filename(
            input$title, input$subdir, shiny::isolate(input$format), input$date
          )
        )
      })
      shiny::observe({
        if (!grepl('^\\s*$', input$file)) shiny::updateTextInput(
          session, 'slug', value = blogdown:::post_slug(input$file)
        )
      })
      shiny::observeEvent(input$format, {
        f = input$file
        if (f != '') shiny::updateTextInput(
          session, 'file', value = xfun::with_ext(f, input$format)
        )
      }, ignoreInit = TRUE)
      shiny::observeEvent(input$done, {
        if (grepl('^\\s*$', input$file)) return(
          warning('The filename is empty!', call. = FALSE)
        )
        if (is.null(getOption('blogdown.author'))) options(blogdown.author = input$author)
        blogdown::new_post(
          input$title, author = input$author, ext = input$format,
          categories = input$cat, tags = input$tag,
          file = gsub('[-[:space:]]+', '-', input$file),
          slug = input$slug, subdir = input$subdir, date = input$date,
          kind = input$kind
        )
        shiny::stopApp()
      })
      shiny::observeEvent(input$cancel, {
        shiny::stopApp()
      })
    },
    stopOnCancel = FALSE, viewer = shiny::dialogViewer('New Post', height = 500)
  )
})
