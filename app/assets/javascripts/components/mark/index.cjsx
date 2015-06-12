React                   = require 'react'
SubjectSetViewer        = require '../subject-set-viewer'
coreTools               = require 'components/core-tools'
FetchSubjectSetsMixin   = require 'lib/fetch-subject-sets-mixin'
BaseWorkflowMethods     = require 'lib/workflow-methods-mixin'
JSONAPIClient           = require 'json-api-client' # use to manage data?
ForumSubjectWidget      = require '../forum-subject-widget'


API                     = require '../../lib/api'

module.exports = React.createClass # rename to Classifier
  displayName: 'Mark'

  propTypes:
    workflow: React.PropTypes.object.isRequired

  mixins: [FetchSubjectSetsMixin, BaseWorkflowMethods] # load subjects and set state variables: subjects, currentSubject, classification

  getInitialState: ->
    currentSubjectSet:            null
    currentSubject:               null
    workflow:                     @props.workflow
    # project:        @props.project
    # currentTask:    @props.workflow.tasks[@props.workflow.first_task]
    taskKey:                      null
    # annotation: {}
    classifications:              []
    classificationIndex:          0

  componentWillMount: ->
    completion_assessment_task = {
        "generates_subject_type": null,
        "instruction": "Is there anything left to mark?",
        "key": "completion_assessment_task",
        "next_task": null,
        "tool": "pickOne",
        "tool_config": {
            "options": {
                "complete_subject": {
                    "label": "yes",
                    "next_task": null
                },
                "incomplete_subject": {
                    "label": "no",
                    "next_task": null
                }
            }
        },
        "subToolIndex": 0
      }

    @props.workflow.tasks["completion_assessment_task"] = completion_assessment_task
    @setState
      taskKey: @props.workflow.first_task
    # TODO: insert the final task into workflow.tasks

    @beginClassification()


  render: ->
    return null unless @state.currentSubjectSet?
    console.log "mark/index state", @state
    console.log "@state.currentTask", @state.currentTask

    # TODO: can we delete the commented out code below?
    # annotations = @props.classification.annotations
    # currentAnnotation = if annotations.length is 0 then {} else annotations[annotations.length-1]

    currentTask = @props.workflow.tasks[@state.taskKey] # [currentAnnotation?.task]
    TaskComponent = @getCurrentTool() # coreTools[currentTask.tool]
    onFirstAnnotation = @state.taskKey == @props.workflow.first_task

    if currentTask.tool is 'pick_one'
      currentAnswer = currentTask.tool_config.options?[currentAnnotation.value]
      waitingForAnswer = not currentAnswer

    <div className="classifier">
      <div className="subject-area">
        { if @state.noMoreSubjectSets
            style = marginTop: "50px"
            <p style={style}>There is nothing left to do. Thanks for your work and please check back soon!</p>
          else if @state.currentSubjectSet?
            <SubjectSetViewer
              subject_set={@state.currentSubjectSet}
              workflow={@props.workflow}
              task={currentTask}
              annotation={@getCurrentClassification().annotation ? {}}
              subToolIndex={@getCurrentClassification().annotation?.subToolIndex}
              onComplete={@handleToolComplete}
              onChange={@handleDataFromTool}
              onViewSubject={@handleViewSubject}
            />
        }
      </div>
      <div className="task-area">
        <div className="task-container">
          <TaskComponent
            task={currentTask}
            onChange={@handleDataFromTool}
            annotation={@getCurrentClassification().annotation ? {}}
            subToolIndex={@getCurrentClassification().annotation?.subToolIndex}
          />
          <hr/>
          <nav className="task-nav">
            <button type="button" className="back minor-button" disabled={onFirstAnnotation} onClick={@destroyCurrentAnnotation}>Back</button>
            { if @getNextTask()?
                <button type="button" className="continue major-button" disabled={waitingForAnswer} onClick={@advanceToNextTask}>Next</button>
              else
                if @state.taskKey == "completion_assessment_task"
                  <button type="button" className="continue major-button" disabled={waitingForAnswer} onClick={@completeSubjectSet}>Next Subject</button>
                else
                  <button type="button" className="continue major-button" disabled={waitingForAnswer} onClick={@completeSubjectSet}>Done</button>
            }
          </nav>
        </div>

        <div className="forum-holder">
          <ForumSubjectWidget subject_set = @state.currentSubjectSet />
        </div>

      </div>
    </div>

  # User changed currently-viewed subject:
  handleViewSubject: (subject) ->
    @setState
      currentSubject: subject

  # User somehow indicated current task is complete; commit current classification
  handleToolComplete: (d) ->
    console.log 'handleToolComplete(): DATA = ', d
    console.log 'TASK IS COMPLETE!'
    @handleDataFromTool(d)
    @commitClassification()
    @beginClassification()

  # Handle user selecting a pick/drawing tool:
  handleDataFromTool: (d) ->
    classifications = @state.classifications
    classifications[@state.classificationIndex].annotation[k] = v for k, v of d

    @forceUpdate()
    @setState
      classifications: classifications

  destroyCurrentAnnotation: ->
    # TODO: implement mechanism for going backwards to previous classification, potentially deleting later classifications from stack:
    console.log "WARN: destroyCurrentAnnotation not implemented"
    # @props.classification.annotations.pop()

  completeSubjectSet: ->
    console.log "currentTask from #completeSubjectSet", @state.currentTask
    if @state.taskKey != "completion_assessment_task"
      @setState
        taskKey: "completion_assessment_task"
    else
      console.log "before commit of completeSubjectSet"
      @commitClassification()

window.React = React
