test(
	'CraftingRecipe',
	{
		Constructor = {
			['Item Count'] = function(t)
				local obj = CraftingRecipe('item1', {'item2', 'item3', 'item3'}, 1)

				t.assertEqual(obj.itemCount, 3)
			end,
			['Correct Item Count'] = function(t)
				local obj = CraftingRecipe('stick', {'plank', nil, nil, 'plank'}, 4)

				t.assertEqual(obj.itemCount, 2)
			end,
			['Correct Items Required'] = function(t)
				local obj = CraftingRecipe('stick', {'plank', nil, nil, 'plank', 'log'}, 4)
				t.assertTableEqual(obj.items, {['plank'] = 2, ['log'] = 1})
				--verify the table equals method
				t.assertEqual(obj.items['plank'], 2)
				t.assertEqual(obj.items['log'], 1)
			end
		}

		-- TODO: more tests
	}
)
