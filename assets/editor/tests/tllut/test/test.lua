local tllut = require("src.tllut")

function sometest()
   print("Running test!")
   assertEquals("x", "x")
   assertEquals(123, 321)
end

function otherTest()
   assertEquals(0,0)
   assertEquals(true, false)

   assertArrayEquals({"Hello", "World"}, {"ROFL", "LOL"})
   assertArrayEquals({0, 0}, {0, 0})
end

function emptyTest()

end

tllut:addSuite({
	  ["sometest"] = sometest,
	  ["otherTest"] = otherTest,
	  ["emptyTest"] = emptyTest
})

tllut:runAll()
tllut:printResult()
