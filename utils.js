function setTimeout(foo, delay) {
    let timer = Qt.createQmlObject("import QtQuick 2.0; Timer {}", root);
    timer.interval = delay;
    timer.triggered.connect(foo);
    timer.start();
}

// Read a JSON file and returns its content
function readFile(fileUrl) {
    var request = new XMLHttpRequest();
    request.open("GET", fileUrl, false);
    request.send(null);
    if (request.responseText == "")
        return null;
    return JSON.parse(request.responseText);
}

// Write a JS object to a file, in JSON
// WARNING: the file is actually written after QT events have been processed
// The next functions after saveFile should then call Qt.callLater for instance
// or setTimeout(foo, 0)
function saveFile(fileUrl, json_obj) {
    var request = new XMLHttpRequest();
    request.open("PUT", fileUrl, false);
    request.send(JSON.stringify(json_obj));
    return request.status;
}



