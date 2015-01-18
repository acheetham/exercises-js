React = require('react')
{Exercise} = require('./components')
HTMLBars = require('./bars/htmlbars')
ExerciseActionsStore = require('./flux/exercise')

window.React = React # for dev tools
window.ExerciseActionsStore = ExerciseActionsStore


module.exports = (root, config) ->

  randRange = (min, max) ->
    Math.floor(Math.random() * (max - min + 1)) + min

  # Generate the variables
  if config.logic
    state = {}
    for key, val of config.logic.inputs
      state[key] = randRange(val.start, val.end)

    for key, val of config.logic.outputs
      val = val(state)
      try
        val = parseInt(val)
        # Inject commas
        val = val.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',')
      catch
        ''
      state[key] = val

  # -------------------------------
  # Generate the HTML using HTMLBars

  DIV = document.createElement('div')

  transformToString = (val, state) ->
    DIV.innerHTML = ''
    fragment = HTMLBars(val)(state)
    DIV.appendChild(fragment)
    DIV.innerHTML


  ids = 0

  barsify = (obj) ->
    if typeof obj is 'object'

      # Add Id's to objects unless the obj is an array or it is a multiselect option `(a) and (b)`
      obj.id ?= "id-#{ids++}" unless Array.isArray(obj) or Array.isArray(obj.value)

      if obj.formats
        # Build each variant
        obj.variants = {}
        obj.format = obj.formats[0]
        for format in obj.formats
          variant = switch format
            when 'multiple-choice' then {stem_html:obj.stem_html, answers:obj.answers,correct:obj.correct, answer:obj.answer}
            when 'multiple-select' then {stem_html:obj.stem_html, answers:obj.answers,correct:obj.correct}
            when 'matching' then {stem_html:obj.stem_html, answers:obj.answers, items:obj.items}
            when 'true-false'
              a = obj.answers[0]
              o =
                stem_html: obj.stem_html.replace(/____/, a.content or a.value)
                answers: obj.answers
                correct: true
              o
            else # 'short-answer' or 'fill-in-the-blank'
              o =
                stem_html: obj.stem_html
                answers: obj.answers
                correct: obj.correct
                answer: obj.answer
              o

          # Make sure each question has an id
          variant.id = "variantid-#{ids++}"

          obj.variants[format] = variant

      for key, val of obj
        if typeof val is 'string'
          obj[key] = transformToString(val, state)
        else
          obj[key] = barsify(val)
    obj

  barsify(config)

  React.renderComponent(Exercise({config}), root)