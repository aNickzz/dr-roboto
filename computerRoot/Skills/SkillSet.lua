SkillSet = Class()
SkillSet.ClassName = 'SkillSet'

function SkillSet.GetDefaultSkillSet()
	local skillSet = SkillSet()

	skillSet:addSkill(TreeFarmSkill())
	skillSet:addSkill(ChopTreeSkill())
	skillSet:addSkill(DanceSkill())
	skillSet:addSkill(GatherSandSkill())
	skillSet:addSkill(CraftItemSkill())
	skillSet:addSkill(NeedleMineSkill())
	skillSet:addSkill(SetupFurnaceSkill())
	skillSet:addSkill(SmeltItemSkill())

	return skillSet
end

function SkillSet:constructor()
	self._skills = {}

	self:addSkill(DefaultSkill())
end

function SkillSet:addSkill(skill)
	assertType(skill, Skill)

	table.insert(self._skills, skill)

	table.sort(
		self._skills,
		function(a, b)
			return a.priority > b.priority
		end
	)
end

function SkillSet:getSkillCount()
	return #self._skills
end

function SkillSet:getSkillForTask(task)
	assertType(task, Task)

	for _, skill in ipairs(self._skills) do
		if (skill:canHandleTask(task)) then
			return skill
		end
	end
end

function SkillSet:getSkills()
	local r = {}

	for _, skill in ipairs(self._skills) do
		table.insert(r, skill)
	end

	return r
end
