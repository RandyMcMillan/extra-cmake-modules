import QtQuick 2.11
import QtTest 1.11

import EcmTest 1.2.3

TestCase {
    id: testCase
    name: "AnotherTestType Instantiation Test"

    width: 400
    height: 400
    visible: true
    when: windowShown

    Component {
        id: component
        AnotherTestType { }
    }

    function test_create() {
        // Create the object
        var object = createTemporaryObject(component, testCase)

        // Verify that it was created.
        verify(object)

        // Verify that any object completion logic was run successfully.
        if (object instanceof Item) {
            // If it is an item we can make sure it renders

            // Ensure it is visible, otherwise rendering will never happen.
            object.visible = true

            // Also make sure to set an initial size, so that rendering will
            // actually render something.
            object.width = 100
            object.height = 100

            verify(waitForRendering(object))
        } else {
            // If it is not an item it won't render so just wait a bit
            wait(100)
            verify(object)
        }
    }
}
