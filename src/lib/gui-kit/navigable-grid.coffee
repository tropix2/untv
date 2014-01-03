###
UNTV - navigrid
Author: Gordon Hall

Accepts an unordered list selector or element and creates
a navigable grid instance
###

SmartAdjuster  = require "./smart-adjuster"
$              = require "../../vendor/jquery-2.0.3"
{EventEmitter} = require "events"

class NavigableGrid extends EventEmitter
  constructor: (@container, @remote, @adjust_x, @adjust_y) ->
    @container = $ @container
    @scroller  = $ "<div class='navigrid'/>"
    @container.append @scroller
    @container.css overflow: "hidden"
    @onselect = -> # default to empty fn, but should be overridden by user
    ($ window).bind "resize", => do @populate
    do @bindRemoteControls

  populate: (list_data, template_fn) =>
    @data   ?= list_data
    @render ?= template_fn or ->
    # use smart adjuster to size the container
    # first get x and y adjuster sizes
    adjuster = new SmartAdjuster @container, @adjust_x, @adjust_y
    # determine the size of a single list item template
    pseudo_item = $ "<li/>"
    # pseudo_item.css opacity: 0
    pseudo_item.html @render @data[0]
    @scroller.append pseudo_item
    # determine size of container and items
    item_width   = pseudo_item.outerWidth()
    item_height  = pseudo_item.outerHeight()
    row_items    = Math.floor adjuster.width / item_width
    total_rows   = Math.ceil @data.length / row_items
    @row_width    = item_width * row_items
    rows_visible = Math.floor adjuster.height / item_height
    @row_height   = adjuster.height / rows_visible
    # create a set of <ul>'s containing <li>'s consistent
    # with the width of the container
    @scroller.empty()
    row_counter = 0
    # for every row we expect, create an <ul>
    @scroller.append $ "<ul/>" for row in [0..total_rows]
    # setup width and height of rows
    rows = $ "ul", @container
    rows.width @row_width
    rows.height @row_height

    for item, index in @data
      next_row = index isnt 0 and (index % row_items) is 0
      # determine whether or not to add to next row
      if next_row then row_counter++
      target_row = $ rows[row_counter]
      # append output to the target row
      target_row.append "<li>#{@render item}</li>"

    ($ "li", @scroller).first().addClass @selected_item_classname

  nextItem: =>
    adjacent = do @adjacent
    if adjacent.right.length
      @getCurrentItem().removeClass @selected_item_classname
      ($ adjacent.right).addClass @selected_item_classname
    else if @getCurrentRow().next()
      ($ "li", @getCurrentRow().next()).first().addClass @selected_item_classname
      @last_item.removeClass @selected_item_classname
    else
      @emit "bounds_reached", direction: "right"
    # reference this item as the last one touched
    @last_item = do @getCurrentItem

  prevItem: =>
    adjacent = do @adjacent
    if adjacent.left.length
      @getCurrentItem().removeClass @selected_item_classname
      ($ adjacent.left).addClass @selected_item_classname
    else if @getCurrentRow().prev()
      ($ "li", @getCurrentRow().prev()).last().addClass @selected_item_classname
      @last_item.removeClass @selected_item_classname
    else
      @emit "bounds_reached", direction: "left"
    # reference this item as the last one touched
    @last_item = do @getCurrentItem

  nextRow: =>
    adjacent = do @adjacent
    if not @is_scrolling
      if adjacent.below
        @getCurrentItem().removeClass @selected_item_classname
        ($ adjacent.below).addClass @selected_item_classname
        @scroll "down"
      else
        @emit "bounds_reached", direction: "down"
    # reference this item as the last one touched
    @last_item = do @getCurrentItem

  prevRow: =>
    adjacent = do @adjacent
    if not @is_scrolling
      if adjacent.above
        @getCurrentItem().removeClass @selected_item_classname
        ($ adjacent.above).addClass @selected_item_classname
        @scroll "up"
      else
        @emit "bounds_reached", direction: "up"
    # reference this item as the last one touched
    @last_item = do @getCurrentItem

  giveFocus: =>
    @focused = yes
    @scroller.addClass @focused_area_classname
    if not ($ "li.selected", @scroller).length
      ($ "li", @scroller).first().addClass @selected_item_classname

  releaseFocus: =>
    @focused = no
    @scroller.removeClass @focused_area_classname

  getCurrentItem: => $ "li.#{@selected_item_classname}", @container
  last_item: null
  getCurrentRow: => @getCurrentItem().parent()

  adjacent: =>
    current = do @getCurrentItem
    index   = ($ "li", @getCurrentRow()).index current
    # return this stuff
    items   =
      above: ($ "li", current.parent().prev())[index] or null
      below: ($ "li", current.parent().next())[index] or null
      left:  current.prev() or null
      right: current.next() or null

  scroll: (direction = "down") =>
    distance = if direction is "up" then @row_height else -@row_height
    position = parseInt @scroller.css "margin-top"
    @is_scrolling = yes
    @scroller.animate 
      marginTop: "#{position + distance}px"
    , @scroll_speed, => @is_scrolling = no

  bindRemoteControls: =>
    @remote.on "scroll:up", => do @prevRow if @focused
    @remote.on "scroll:down", => do @nextRow if @focused
    @remote.on "go:next", => do @nextItem if @focused
    @remote.on "go:back", => do @prevItem if @focused
    @remote.on "go:select", => if @focused then @onselect @getCurrentItem()

  selected_item_classname: "navigrid-selected"
  focused_area_classname: "navigrid-focused"
  scroll_speed: 200

module.exports = NavigableGrid