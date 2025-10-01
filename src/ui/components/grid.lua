-- Smart UI Framework: Grid Component (Table-like Layout)
-- Handles multi-column/row layouts with flexible sizing

local Component = require("src.ui.components.component")

local Grid = setmetatable({}, {__index = Component})
Grid.__index = Grid

function Grid.new(props)
    props = props or {}
    local self = Component.new(props)
    setmetatable(self, Grid)
    
    -- Grid properties
    self.columns = props.columns or 1           -- Number of columns
    self.rows = props.rows or nil               -- Number of rows (nil = auto)
    self.columnGap = props.columnGap or 0       -- Horizontal gap
    self.rowGap = props.rowGap or 0             -- Vertical gap
    self.cellAlign = props.cellAlign or "start" -- Cell alignment: "start" | "center" | "end" | "stretch"
    
    -- Column sizing (array of numbers or "auto" or "flex")
    -- Example: {100, "auto", "flex", 200}
    self.columnSizes = props.columnSizes or nil
    
    -- Row sizing (array of numbers or "auto" or "flex")
    self.rowSizes = props.rowSizes or nil
    
    -- Background styling
    self.backgroundColor = props.backgroundColor or nil
    self.borderColor = props.borderColor or nil
    self.borderWidth = props.borderWidth or 0
    self.cellBorderColor = props.cellBorderColor or nil
    self.cellBorderWidth = props.cellBorderWidth or 0
    
    return self
end

-- Measure intrinsic size based on grid layout
function Grid:measure(availableWidth, availableHeight)
    local paddingX = self.padding[2] + self.padding[4]
    local paddingY = self.padding[1] + self.padding[3]
    local borderOffset = self.borderWidth * 2
    
    local innerAvailableWidth = availableWidth - paddingX - borderOffset
    local innerAvailableHeight = availableHeight - paddingY - borderOffset
    
    -- Calculate number of rows
    local visibleChildren = {}
    for _, child in ipairs(self.children) do
        if child.visible then
            table.insert(visibleChildren, child)
        end
    end
    
    local numRows = self.rows or math.ceil(#visibleChildren / self.columns)
    
    -- Measure all children to get their intrinsic sizes
    for _, child in ipairs(visibleChildren) do
        child:measure(innerAvailableWidth / self.columns, innerAvailableHeight / numRows)
    end
    
    -- Calculate column widths
    local columnWidths = self:calculateColumnWidths(visibleChildren, innerAvailableWidth)
    
    -- Calculate row heights
    local rowHeights = self:calculateRowHeights(visibleChildren, columnWidths, numRows)
    
    -- Calculate total size
    local totalWidth = 0
    for _, width in ipairs(columnWidths) do
        totalWidth = totalWidth + width
    end
    totalWidth = totalWidth + (self.columnGap * (self.columns - 1))
    
    local totalHeight = 0
    for _, height in ipairs(rowHeights) do
        totalHeight = totalHeight + height
    end
    totalHeight = totalHeight + (self.rowGap * (numRows - 1))
    
    -- Add padding and border
    totalWidth = totalWidth + paddingX + borderOffset
    totalHeight = totalHeight + paddingY + borderOffset
    
    -- Clamp to constraints
    self.intrinsicSize = {
        width = math.min(math.max(totalWidth, self.minWidth), self.maxWidth),
        height = math.min(math.max(totalHeight, self.minHeight), self.maxHeight)
    }
    
    -- Cache for layout phase
    self._columnWidths = columnWidths
    self._rowHeights = rowHeights
    self._numRows = numRows
    
    return self.intrinsicSize
end

-- Calculate column widths based on content and sizing rules
function Grid:calculateColumnWidths(children, availableWidth)
    local columnWidths = {}
    
    -- If column sizes explicitly defined, use them
    if self.columnSizes then
        local fixedWidth = 0
        local flexColumns = 0
        local autoColumns = {}
        
        for col = 1, self.columns do
            local size = self.columnSizes[col] or "auto"
            
            if type(size) == "number" then
                columnWidths[col] = size
                fixedWidth = fixedWidth + size
            elseif size == "flex" then
                columnWidths[col] = 0
                flexColumns = flexColumns + 1
            else  -- "auto"
                columnWidths[col] = 0
                table.insert(autoColumns, col)
            end
        end
        
        -- Calculate auto column widths based on content
        for _, col in ipairs(autoColumns) do
            local maxWidth = 0
            for i, child in ipairs(children) do
                local childCol = ((i - 1) % self.columns) + 1
                if childCol == col then
                    maxWidth = math.max(maxWidth, child.intrinsicSize.width)
                end
            end
            columnWidths[col] = maxWidth
            fixedWidth = fixedWidth + maxWidth
        end
        
        -- Distribute remaining space to flex columns
        local gaps = self.columnGap * (self.columns - 1)
        local remainingWidth = math.max(0, availableWidth - fixedWidth - gaps)
        if flexColumns > 0 then
            local flexWidth = remainingWidth / flexColumns
            for col = 1, self.columns do
                if self.columnSizes[col] == "flex" then
                    columnWidths[col] = flexWidth
                end
            end
        end
    else
        -- Equal column widths
        local gaps = self.columnGap * (self.columns - 1)
        local columnWidth = (availableWidth - gaps) / self.columns
        
        for col = 1, self.columns do
            columnWidths[col] = columnWidth
        end
    end
    
    return columnWidths
end

-- Calculate row heights based on content
function Grid:calculateRowHeights(children, columnWidths, numRows)
    local rowHeights = {}
    
    -- If row sizes explicitly defined, use them
    if self.rowSizes then
        for row = 1, numRows do
            local size = self.rowSizes[row] or "auto"
            
            if type(size) == "number" then
                rowHeights[row] = size
            else  -- "auto" - calculate from content
                rowHeights[row] = 0
                for i, child in ipairs(children) do
                    local childRow = math.ceil(i / self.columns)
                    if childRow == row then
                        rowHeights[row] = math.max(rowHeights[row], child.intrinsicSize.height)
                    end
                end
            end
        end
    else
        -- Auto row heights based on tallest cell
        for row = 1, numRows do
            rowHeights[row] = 0
            for i, child in ipairs(children) do
                local childRow = math.ceil(i / self.columns)
                if childRow == row then
                    rowHeights[row] = math.max(rowHeights[row], child.intrinsicSize.height)
                end
            end
        end
    end
    
    return rowHeights
end

-- Layout children in grid cells
function Grid:layout(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.layoutDirty = false
    
    -- Calculate inner bounds
    local borderOffset = self.borderWidth
    local innerX = x + self.padding[4] + borderOffset
    local innerY = y + self.padding[1] + borderOffset
    local innerWidth = width - self.padding[2] - self.padding[4] - (borderOffset * 2)
    local innerHeight = height - self.padding[1] - self.padding[3] - (borderOffset * 2)
    
    -- Get visible children
    local visibleChildren = {}
    for _, child in ipairs(self.children) do
        if child.visible then
            table.insert(visibleChildren, child)
        end
    end
    
    if #visibleChildren == 0 then return end
    
    -- Use cached dimensions from measure phase
    local columnWidths = self._columnWidths or {}
    local rowHeights = self._rowHeights or {}
    
    -- Position each child in its cell
    local currentY = innerY
    for row = 1, self._numRows do
        local currentX = innerX
        local rowHeight = rowHeights[row] or 0
        
        for col = 1, self.columns do
            local cellIndex = (row - 1) * self.columns + col
            if cellIndex > #visibleChildren then break end
            
            local child = visibleChildren[cellIndex]
            local columnWidth = columnWidths[col] or 0
            
            -- Calculate cell position and size
            local cellX = currentX
            local cellY = currentY
            local cellWidth = columnWidth
            local cellHeight = rowHeight
            
            -- Apply cell alignment
            local childX = cellX
            local childY = cellY
            local childWidth = child.intrinsicSize.width
            local childHeight = child.intrinsicSize.height
            
            if self.cellAlign == "center" then
                childX = cellX + (cellWidth - childWidth) / 2
                childY = cellY + (cellHeight - childHeight) / 2
            elseif self.cellAlign == "end" then
                childX = cellX + cellWidth - childWidth
                childY = cellY + cellHeight - childHeight
            elseif self.cellAlign == "stretch" then
                childWidth = cellWidth
                childHeight = cellHeight
            end
            
            -- Layout the child
            child:layout(childX, childY, childWidth, childHeight)
            
            currentX = currentX + columnWidth + self.columnGap
        end
        
        currentY = currentY + rowHeight + self.rowGap
    end
end

-- Render grid background, borders, and children
function Grid:render()
    if not self.visible then return end
    
    local love = love or _G.love
    
    -- Save previous state
    local r, g, b, a = love.graphics.getColor()
    
    -- Draw background
    if self.backgroundColor then
        love.graphics.setColor(self.backgroundColor)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    end
    
    -- Draw cell borders
    if self.cellBorderColor and self.cellBorderWidth > 0 then
        love.graphics.setColor(self.cellBorderColor)
        love.graphics.setLineWidth(self.cellBorderWidth)
        
        local borderOffset = self.borderWidth
        local innerX = self.x + self.padding[4] + borderOffset
        local innerY = self.y + self.padding[1] + borderOffset
        
        -- Draw vertical lines
        local currentX = innerX
        for col = 0, self.columns do
            if col > 0 and col < self.columns then
                love.graphics.line(currentX, innerY, currentX, innerY + self.height - self.padding[1] - self.padding[3] - borderOffset * 2)
            end
            if col < self.columns then
                currentX = currentX + (self._columnWidths[col + 1] or 0) + self.columnGap
            end
        end
        
        -- Draw horizontal lines
        local currentY = innerY
        for row = 0, self._numRows do
            if row > 0 and row < self._numRows then
                love.graphics.line(innerX, currentY, innerX + self.width - self.padding[2] - self.padding[4] - borderOffset * 2, currentY)
            end
            if row < self._numRows then
                currentY = currentY + (self._rowHeights[row + 1] or 0) + self.rowGap
            end
        end
    end
    
    -- Draw outer border
    if self.borderColor and self.borderWidth > 0 then
        love.graphics.setColor(self.borderColor)
        love.graphics.setLineWidth(self.borderWidth)
        love.graphics.rectangle("line", 
            self.x + self.borderWidth/2, 
            self.y + self.borderWidth/2, 
            self.width - self.borderWidth, 
            self.height - self.borderWidth
        )
    end
    
    -- Restore color and render children
    love.graphics.setColor(r, g, b, a)
    
    for _, child in ipairs(self.children) do
        child:render()
    end
end

return Grid
