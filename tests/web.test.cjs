const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { test } = require('node:test');
const vm = require('node:vm');

function loadDemo() {
    const elements = new Map();
    const buttons = ['USD', 'CNY'].map(textContent => {
        const classes = new Set(textContent === 'USD' ? ['active'] : []);
        return { textContent, classes, classList: {
            remove: name => classes.delete(name),
            toggle: (name, active) => active ? classes.add(name) : classes.delete(name),
        } };
    });
    const document = {
        getElementById(id) {
            if (!elements.has(id)) elements.set(id, { textContent: '' });
            return elements.get(id);
        },
        querySelectorAll: () => buttons,
        createElement: () => ({ style: {} }),
        head: { appendChild() {} },
        body: { appendChild() {} },
    };
    const context = vm.createContext({ document, setInterval() {}, setTimeout() {} });
    const html = readFileSync(new URL('../index.html', `file://${__filename}`), 'utf8');
    vm.runInContext(html.match(/<script>([\s\S]*?)<\/script>/)[1], context);
    return { context, elements, buttons };
}

test('currency switch works without the nonstandard global event', () => {
    const { context, elements, buttons } = loadDemo();
    vm.runInContext("switchCurrency('CNY')", context);
    assert.equal(elements.get('highPrice').textContent, '¥837,334.00');
    assert.equal(buttons[0].classes.has('active'), false);
    assert.equal(buttons[1].classes.has('active'), true);
    vm.runInContext("switchCurrency('USD')", context);
    assert.equal(elements.get('highPrice').textContent, '$116,995.00');
    assert.equal(buttons[0].classes.has('active'), true);
    assert.equal(buttons[1].classes.has('active'), false);
});

test('invalid currency leaves the current view intact', () => {
    const { context, elements, buttons } = loadDemo();
    const before = elements.get('highPrice').textContent;
    vm.runInContext("switchCurrency('__proto__')", context);
    assert.equal(elements.get('highPrice').textContent, before);
    assert.equal(buttons[0].classes.has('active'), true);
});
