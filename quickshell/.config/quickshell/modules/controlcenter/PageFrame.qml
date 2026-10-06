import QtQuick
import QtQuick.Layouts
import "../../"
import "../../theme"
import "Nav.js" as Nav

// Background, title and back button shared by all submenus.
// Every property has a default, override it in the page (e.g. title, color, border.width).
Rectangle {
    id: frame

    default property alias content: body.data

    // false removes the blur behind the control center, e.g. to watch changes live
    property bool blurBackground: true

    // Header
    property string title: ""
    property bool showHeader: true
    property color titleColor: Theme.colors.accent
    property real titleSize: 18 * Theme.scale * Theme.font.scale
    property bool titleBold: true
    property bool showBack: true
    property string backIcon: "arrow_back"
    property color backColor: Theme.colors.text
    property real backSize: 18 * Theme.scale

    // Layout, the window follows this size
    implicitWidth: 480 * Theme.scale
    implicitHeight: 440 * Theme.scale
    property real contentMargin: 20 * Theme.scale
    property real spacing: 16 * Theme.scale

    signal navigate(string target)

    color: Theme.colors.bg
    radius: Theme.rounding * Theme.scale

    // Left is backward, Right is forward, each the mirror of the other.
    // Left: neighbour to the left, else the first item of the previous group, else the back button.
    // Right: on the back button, the first item of the first group; else the neighbour to the right,
    // else the first item of the next group. Up/Down move within the same column regardless of group
    // and wrap around at the ends of the page.
    // hjkl always navigate like the arrows (they bubble up here unless a text field takes them).
    // Sliders and toggles consume the Left/Right arrows themselves, hjkl still navigate.
    // Items that use the arrows otherwise accept them, or set event.accepted = false at their edge.
    Keys.onLeftPressed: goLeft()
    Keys.onRightPressed: goRight()
    Keys.onUpPressed: goUp()
    Keys.onDownPressed: goDown()
    Keys.onPressed: event => {
        const dir = Nav.vim(event);
        if (!dir)
            return;
        event.accepted = true;
        if (dir === "left")
            goLeft();
        else if (dir === "right")
            goRight();
        else if (dir === "up")
            goUp();
        else
            goDown();
    }

    function goLeft() {
        if (backButton.activeFocus) {
            navigate("main");
            return;
        }
        if (moveSide(-1))
            return;
        const all = stops();
        const cur = currentStop(all);
        const prevStart = cur && cur.navGroup >= 0 ? prevGroupStart(all, all.indexOf(cur), cur.navGroup) : null;
        if (prevStart) {
            prevStart.forceActiveFocus();
            scrollIntoView(prevStart);
        } else if (showBack) {
            backButton.forceActiveFocus();
        }
    }

    function goRight() {
        if (backButton.activeFocus) {
            const all = stops();
            const first = all.find(item => item !== backButton);
            if (first) {
                first.forceActiveFocus();
                scrollIntoView(first);
            }
            return;
        }
        if (moveSide(1))
            return;
        const all = stops();
        const cur = currentStop(all);
        const nextStart = cur && cur.navGroup >= 0 ? nextGroupStart(all, all.indexOf(cur), cur.navGroup) : null;
        if (nextStart) {
            nextStart.forceActiveFocus();
            scrollIntoView(nextStart);
        }
    }

    // Past the last stop Down wraps to the first one, past the first Up wraps to the last
    function goDown() {
        if (!moveVertical(1))
            wrapTo(false);
    }

    function goUp() {
        if (!moveVertical(-1))
            wrapTo(true);
    }

    function wrapTo(last) {
        const all = stops().filter(item => item.visible);
        const target = last ? all[all.length - 1] : all[0];
        if (target) {
            target.forceActiveFocus();
            scrollIntoView(target);
        }
    }

    // Which of `all` currently holds focus, walking up for nested controls
    function currentStop(all) {
        let cur = Window.window?.activeFocusItem;
        while (cur && !all.includes(cur))
            cur = cur.parent;
        return cur;
    }

    // First stop of the group immediately before `group`, null if `group` is the first one
    function prevGroupStart(all, idx, group) {
        let i = idx - 1;
        while (i >= 0 && all[i].navGroup === group)
            i--;
        if (i < 0 || !(all[i].navGroup >= 0))
            return null;
        const prevGroup = all[i].navGroup;
        return all.find(item => item.navGroup === prevGroup);
    }

    // First stop of the group immediately after `group`, null if `group` is the last one
    function nextGroupStart(all, idx, group) {
        let i = idx + 1;
        while (i < all.length && all[i].navGroup === group)
            i++;
        if (i >= all.length || !(all[i].navGroup >= 0))
            return null;
        return all[i];
    }

    // dir is -1 (up) or 1 (down). Candidates must lie completely on that side, the closest
    // column (cx) then closest distance wins, so movement stays within the same column.
    function moveVertical(dir) {
        const all = stops();
        const cur = currentStop(all);
        if (!cur)
            return false;
        const box = item => {
            const p = item.mapToItem(frame, 0, 0);
            return {
                top: p.y,
                bottom: p.y + item.height,
                cx: p.x + item.width / 2,
                cy: p.y + item.height / 2
            };
        };
        const a = box(cur);
        let best = null;
        let bestScore = Infinity;
        for (const c of all) {
            if (c === cur || !c.visible)
                continue;
            const b = box(c);
            if (dir > 0 ? b.top < a.bottom : b.bottom > a.top)
                continue;
            const score = Math.abs(b.cx - a.cx) * 1000 + Math.abs(b.cy - a.cy);
            if (score < bestScore) {
                best = c;
                bestScore = score;
            }
        }
        if (best) {
            best.forceActiveFocus();
            scrollIntoView(best);
            return true;
        }
        return false;
    }

    // Pages that grow past the page height wrap their content in a Flickable. Keyboard
    // navigation must keep whatever gets focused on screen, scrolling the nearest Flickable
    // ancestor just enough (not a full recenter) the way KeybindRow already does for itself.
    function scrollIntoView(item) {
        let flick = item.parent;
        while (flick && !("contentY" in flick))
            flick = flick.parent;
        if (!flick)
            return;
        const p = item.mapToItem(flick, 0, 0);
        if (p.y < 0)
            flick.contentY += p.y;
        else if (p.y + item.height > flick.height)
            flick.contentY += p.y + item.height - flick.height;
    }

    // All keyboard stops in chain order
    function stops() {
        const list = [];
        let item = showBack ? backButton : frame.nextItemInFocusChain(true);
        while (item && !list.includes(item) && list.length < 100) {
            list.push(item);
            item = item.nextItemInFocusChain(true);
        }
        return list;
    }

    // dir is -1 (left) or 1 (right). Candidates must lie completely on that side (wide items
    // that span the current one do not count), the closest in height then distance wins.
    // Purely geometric; the Left/Right handlers add the group-jump fallback themselves.
    function moveSide(dir) {
        const all = stops();
        const cur = currentStop(all);
        if (!cur)
            return false;
        const box = item => {
            const p = item.mapToItem(frame, 0, 0);
            return {
                left: p.x,
                right: p.x + item.width,
                cx: p.x + item.width / 2,
                cy: p.y + item.height / 2
            };
        };
        const a = box(cur);
        let best = null;
        let bestScore = Infinity;
        for (const c of all) {
            if (c === cur || !c.visible)
                continue;
            const b = box(c);
            const dy = Math.abs(b.cy - a.cy);
            if (dir > 0 ? b.left < a.right : b.right > a.left)
                continue;
            const score = dy * 1000 + Math.abs(b.cx - a.cx);
            if (score < bestScore) {
                best = c;
                bestScore = score;
            }
        }
        if (best) {
            best.forceActiveFocus();
            scrollIntoView(best);
            return true;
        }
        return false;
    }

    // The back button is the first stop, Down from there enters the page
    function focusDefault() {
        if (showBack)
            backButton.forceActiveFocus();
        else
            forceActiveFocus();
    }

    // A click on empty space takes the focus from a text field so the arrow keys work again
    MouseArea {
        anchors.fill: parent
        onPressed: mouse => {
            frame.forceActiveFocus();
            mouse.accepted = false;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: frame.contentMargin
        spacing: frame.spacing

        RowLayout {
            visible: frame.showHeader
            Layout.fillWidth: true

            Text {
                text: frame.title
                color: frame.titleColor
                font.family: Theme.font.uiFamily
                font.pixelSize: frame.titleSize
                font.bold: frame.titleBold
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                id: backButton

                visible: frame.showBack
                activeFocusOnTab: true
                implicitWidth: 30 * Theme.scale
                implicitHeight: implicitWidth
                radius: Theme.rounding / 2 * Theme.scale
                color: (backArea.containsMouse || activeFocus) ? Qt.alpha(Theme.colors.selection, Theme.focusFill) : Theme.colors.surface
                border.width: activeFocus ? 2 * Theme.scale : 0
                border.color: Theme.colors.focus

                Keys.onReturnPressed: frame.navigate("main")
                Keys.onSpacePressed: frame.navigate("main")

                MaterialIcon {
                    anchors.centerIn: parent
                    icon: frame.backIcon
                    size: frame.backSize
                    iconColor: frame.backColor
                }

                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: frame.navigate("main")
                }
            }
        }

        Item {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
