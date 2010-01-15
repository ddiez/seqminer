require 'test/unit'
require 'Item'
require 'Taxon'
require 'Ortholog'

class TC_Item < Test::Unit::TestCase
	def test_create
		assert_not_nil(Item::Set.new)
		assert_not_nil(Item::Item.new(0))
	end

	def test_add
		is = Item::Set.new
		i1 = Item::Item.new(0)
		i2 = Item::Item.new(2)
		assert_not_nil(is.add(i1))
		assert_not_nil(is << i2)
		assert_equal(2, is.length)
		assert_raise RuntimeError do
			is << i2
		end
	end

	def test_replace
		is = Item::Set.new
		i1 = Item::Item.new(0)
		i2 = Item::Item.new(0)
		assert_not_nil(is << i1)
		assert_nothing_raised RuntimeError do
			is.replace(i2)
		end
	end
	
	def test_get_item_by_id
		is = Item::Set.new
		i1 = Item::Item.new(123)
		is << i1
		assert_equal(123, is.get_item_by_id(123).id)
	end

	def test_each
	end
end

class TC_Taxon < Test::Unit::TestCase
	
	def test_create
		assert_not_nil(Taxon::Set.new)
		assert_not_nil(Taxon::Taxon.new(123, "plasmodium", "falciparum", "3d7", "spp", "plasmodb"))
	end
	
	def test_add
	end
	
	def test_get_taxon_by_name
		ts = Taxon::Set.new
		assert_equal("plasmodium.falciparum_3d7", ts.get_taxon_by_name("plasmodium.falciparum_3d7").name)
	end
	
	def test_filter
		ts = Taxon::Set.new
		
		assert_not_nil(ts.filter_by_name("plasmodium.falciparum_3d7"))
		assert_equal(1, ts.filter_by_name("plasmodium.falciparum_3d7").length)
		#assert_equal(ts.filter_by_name("plasmodium.falciparum_3d7"))
			
		assert_not_nil(ts.filter_by_type("spp"))

		assert_not_nil(ts.filter_by_source("plasmodb"))
	end
end

class TC_Ortholog < Test::Unit::TestCase
	def test_create
		assert_not_nil(Ortholog::Set.new)
		assert_not_nil(Ortholog::Ortholog.new("var", "PFEMP"))
	end
	
	def filter
		os = Ortholog::Set.new
		
		assert_not_nil(os.filter_by_name("var"))
		
#		assert_equal("var", os.filter_by_name("var").name)
#		assert_equal("PFEMP", os.filter_by_name("var").hmm)
	end
end
