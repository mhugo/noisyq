from PyQt5.QtCore import (
    QUrl, pyqtSignal, pyqtProperty, pyqtSlot, QObject, QTimer,
    QMetaObject
)
from PyQt5.QtWidgets import QApplication
from PyQt5.QtQuick import QQuickView, QQuickItem
from PyQt5.QtQml import QQmlEngine, qmlRegisterSingletonType

import sys

import os

from jalv_wrapper import JALVInstance

app = QApplication(sys.argv)
app.setApplicationDisplayName("HOST")

current_path = os.path.abspath(os.path.dirname(__file__))
qml_file = os.path.join(current_path, 'test_menu.qml')

class Utils(QObject):
    @pyqtSlot(QObject, result=str)
    def objectId(self, obj):
        ctxt = QQmlEngine.contextForObject(obj)
        if ctxt:
            return ctxt.nameForObject(obj)
        return "<nocontext>"

    @pyqtSlot(str, result=str)
    def readFile(self, file_name):
        with open(file_name, "r") as fi:
            return fi.read()

    @pyqtSlot(str, str)
    def saveFile(self, file_name, content):
        with open(file_name, "w") as fo:
            fo.write(content)

class LV2Host(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)

        # str -> JALVInstance
        self.__instances = {}

        self.__next_id = 0

    @pyqtSlot(str, result=str)
    def addInstance(self, lv2_name):
        print(">>> addInstance", lv2_name)
        lv2_id = "jalv{}".format(self.__next_id)
        self.__next_id += 1
        instance = JALVInstance(lv2_name, lv2_id)
        self.__instances[lv2_id] = instance
        return lv2_id

    @pyqtSlot(str, str, float)
    def setParameterValue(self, lv2_id, parameter_name, value):
        print(">>> setParameterValue", lv2_id, parameter_name, value)
        instance = self.__instances[lv2_id]
        instance.set_control(parameter_name, value)

class StubHost(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)

        self.__next_id = 0

    @pyqtSlot(str, result=str)
    def addInstance(self, lv2_name):
        print(">>> addInstance", lv2_name)
        lv2_id = "stub{}".format(self.__next_id)
        self.__next_id += 1
        return lv2_id

    @pyqtSlot(str, str, float)
    def setParameterValue(self, lv2_id, parameter_name, value):
        print(">>> setParameterValue", lv2_id, parameter_name, value)

    @pyqtSlot(str, str, result=float)
    def getParameterValue(self, lv2_id, parameter_name):
        import random
        v = random.random()
        print(">>> getParameterValue", lv2_id, parameter_name, v)
        return v

print(sys.argv)
if "--help" in sys.argv:
    print("Arguments:")
    print("\t--help\tThis help screen")
    print("\t--stub\tStub LV2 host")
    sys.exit(0)

if "--stub" in sys.argv:
    lv2Host = StubHost()
else:
    lv2Host = LV2Host()
        
qmlRegisterSingletonType(Utils, 'Utils', 1, 0, "Utils", lambda engine, script_engine: Utils())

view = QQuickView()
view.setResizeMode(QQuickView.SizeViewToRootObject)

view.rootContext().setContextProperty("lv2Host", lv2Host)

view.setSource(QUrl.fromLocalFile(qml_file))
view.engine().quit.connect(app.quit)
view.show()

app.exec_()

