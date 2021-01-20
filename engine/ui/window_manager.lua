Class = require "lib.hump.class"
-- Объединить с UIobject 
-- Объединить с UI_container
-- Сделать два объекта в итоге, горизонтальный лист, вертикальный лист
-- Менеджер окошка, предполагается как менеджер одного небольшого или большого окошка, всех действий в нём и прочего, независимо от остальных таких же окошек
-- Задачей объекта является отображение и считывание событий для объектов в рамках своего оконца
WindowManager = Class {
	init = function(self, x, y, width, height, background)
		self.objects = {}
		self.x = x and x or 0
		self.y = y and y or 0
		self.width = width and width or love.graphics.getWidth()
		self.height = height and height or love.graphics.getHeight()
		self.background = background and background or nil -- Сюда можно впихнуть базовый бэк
    end
}
-- Регистрация объекта в окошке, для его отображения и считывания действий
function WindowManager:registerObject(id, object)
	self.objects[id] = object
end

function WindowManager:getObject(id)
	return self.objects[id]
end

function WindowManager:update(dt)
	for _, object in pairs(self.objects) do
		object:update(dt)
	end
end

-- Отображение объектов, с учётом релативной и фиксированной расположенности
function WindowManager:draw()
	if self.background then
		local width, height = self.background:getDimensions()
		love.graphics.draw(self.background, self.x, self.y, 0, self.width/width, self.height/height )
	end

	for _, object in pairs(self.objects) do
		if object.position == 'relative' then
			local xPos =  (object.right and ((self.x + self.width) - object.right) or (object.left and (self.x + object.left) or self.x + object.x))
			local yPos =  (object.down and ((self.y + self.height) - object.down) or (object.up and (self.y + object.up) or self.y  + object.y))
			object:drawObject( xPos, 
					 		   yPos, 
					 		   object.angle, 
					 		   object.width, 
					 		   object.height)
		elseif object.position == 'fixed' then
			object:draw()
		end
	end
end

-- Обработчик нажатия кнопки мыши на объекты
function WindowManager:mousepressed(x, y)
	local x, y = x-self.x, y-self.y
	for ind, object in pairs(self.objects) do
		if object:getCollision(x, y) then
			if object.startClickInteraction then 
				print(ind, x,y, self.x, self.y)
				object.startClickInteraction(object, x, y)
			end
		elseif object.misClickInteraction then
			object.misClickInteraction(object, x, y)
		end
	end
end

-- Обработчик отпускания кнопки мыши
function WindowManager:mousereleased(x, y)
	for _, object in pairs(self.objects) do
		if object:getCollision(x, y) then
			if object.stopClickInteraction then 
				object.stopClickInteraction(object, x, y)
			end
		end
	end
end
-- Обработчик отпускания кнопки мыши
function WindowManager:keypressed(key)
	for ind, object in pairs(self.objects) do
		if object.keypressed then
			object.keypressed(object, key)
		end
	end
end

return WindowManager