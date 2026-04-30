pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property var  server:       _server
    property bool doNotDisturb: false

    property alias activeNotifications: activeModel
    ListModel { id: activeModel }

    signal notificationAdded(var entry)
    signal notificationDismissed(int nid)

    function dismissById(nid) {
        for (var i = 0; i < activeModel.count; i++) {
            if (activeModel.get(i).nid === nid) {
                var n = activeModel.get(i).notification
                if (n) n.dismiss()
                activeModel.remove(i)
                break
            }
        }
        root.notificationDismissed(nid)
    }

    function expireById(nid) {
        for (var i = 0; i < activeModel.count; i++) {
            if (activeModel.get(i).nid === nid) {
                var n = activeModel.get(i).notification
                if (n) n.expire()
                activeModel.remove(i)
                break
            }
        }
    }

    function clearAll() {
        var notifs = _server.trackedNotifications.values.slice()
        for (var i = 0; i < notifs.length; i++) notifs[i].dismiss()
        activeModel.clear()
    }

    function urgencyDuration(urgency) {
        if (urgency === NotificationUrgency.Critical) return 0
        if (urgency === NotificationUrgency.Low)      return 4000
        return 6000
    }

    NotificationServer {
        id: _server
        keepOnReload:         false
        actionsSupported:     true
        actionIconsSupported: true
        bodySupported:        true
        bodyMarkupSupported:  true
        imageSupported:       true
        persistenceSupported: true
        inlineReplySupported: true

        onNotification: function(notif) {
            notif.tracked = true
            if (root.doNotDisturb) return

            var entry = {
                nid:            notif.id,
                appName:        notif.appName,
                appIcon:        notif.appIcon,
                summary:        notif.summary,
                body:           notif.body,
                image:          notif.image,
                urgency:        notif.urgency,
                notification:   notif,
                timestamp:      Date.now(),
                duration:       root.urgencyDuration(notif.urgency)
            }

            for (var j = 0; j < activeModel.count; j++) {
                if (activeModel.get(j).nid === notif.id) {
                    activeModel.set(j, entry)
                    root.notificationAdded(entry)
                    return
                }
            }

            if (activeModel.count >= 5) activeModel.remove(activeModel.count - 1)
            activeModel.insert(0, entry)
            root.notificationAdded(entry)
        }
    }
}
