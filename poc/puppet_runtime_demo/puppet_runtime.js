export class PuppetRuntime {
  constructor(parts) {
    this.parts = parts;
    this.time = 0;
    this.action = 'idle';
    this.actionTime = 0;
  }

  setAction(name) {
    if (!['idle','walk','talk','gesture','eat','listen'].includes(name)) return;
    if (this.action !== name) {
      this.action = name;
      this.actionTime = 0;
    }
  }

  tick(dt) {
    const d = Math.min(Math.max(dt, 0), 0.05);
    this.time += d;
    this.actionTime += d;
    const t = this.time, a = this.actionTime;
    const breath = Math.sin(t * 1.7) * 0.012;
    const sway = Math.sin(t * 1.15) * 0.018;
    const pose = (id, values) => {
      if (this.parts[id]) Object.assign(this.parts[id].runtime, values);
    };

    for (const id of Object.keys(this.parts)) {
      Object.assign(this.parts[id].runtime, {rotation: 0, x: 0, y: 0, scaleX: 1, scaleY: 1});
    }

    pose('torso', {rotation: sway, scaleY: 1 + breath, y: Math.sin(t * 1.7) * 1.5});

    if (this.action === 'talk') {
      pose('head', {rotation: Math.sin(a * 2.1) * 0.045, y: Math.sin(a * 2.8) * 2});
      pose('armR', {rotation: -0.18 + Math.sin(a * 2.4) * 0.16});
      pose('armL', {rotation: 0.08 + Math.sin(a * 1.7) * 0.04});
    } else if (this.action === 'gesture') {
      const reach = Math.max(0, Math.sin(a * 1.45));
      pose('armR', {rotation: -0.58 * reach, y: -3 * reach});
      pose('armL', {rotation: 0.12 * reach});
      pose('head', {rotation: 0.04 * reach});
    } else if (this.action === 'eat') {
      const reach = Math.max(0, Math.sin(a * 1.25));
      pose('armR', {rotation: -0.9 * reach, y: -10 * reach, x: -4 * reach});
      pose('head', {rotation: -0.08 * reach, y: 2 * reach});
    } else if (this.action === 'listen') {
      pose('head', {rotation: -0.055 + Math.sin(a * 0.8) * 0.025});
      pose('armR', {rotation: 0.04 + Math.sin(a * 0.7) * 0.025});
    } else if (this.action === 'walk') {
      const stride = Math.sin(a * 4.2);
      pose('legL', {rotation: stride * 0.11});
      pose('legR', {rotation: -stride * 0.11});
      pose('armL', {rotation: -stride * 0.10});
      pose('armR', {rotation: stride * 0.10});
      pose('head', {rotation: Math.sin(a * 2.1) * 0.018});
    } else {
      pose('head', {rotation: Math.sin(t * 0.65) * 0.018});
      pose('armR', {rotation: Math.sin(t * 0.9) * 0.025});
      pose('armL', {rotation: Math.sin(t * 0.8 + 1) * 0.018});
    }
    return this.parts;
  }
}
