import AppKit

/// 生成 macOS 菜单栏风格图标（template image，自适应亮/暗模式）
enum MenuBarIcon {
    /// 生成盾牌图标，尺寸适配菜单栏（18pt）
    static func shield() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let ctx = NSGraphicsContext.current!.cgContext
            let s = rect.width
            let inset = s * 0.15
            let r = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)

            // 盾牌形状路径
            let path = CGMutablePath()
            let w = r.width
            let h = r.height
            let x = r.minX
            let y = r.minY

            // 从顶部中间开始，顺时针画盾牌
            path.move(to: CGPoint(x: x + w * 0.3, y: y + h))
            path.addLine(to: CGPoint(x: x, y: y + h * 0.35))
            // 左侧弧线到顶部
            path.addCurve(
                to: CGPoint(x: x + w * 0.2, y: y),
                control1: CGPoint(x: x, y: y + h * 0.12),
                control2: CGPoint(x: x + w * 0.08, y: y)
            )
            // 顶部横线
            path.addLine(to: CGPoint(x: x + w * 0.8, y: y))
            // 右侧弧线下来
            path.addCurve(
                to: CGPoint(x: x + w, y: y + h * 0.35),
                control1: CGPoint(x: x + w * 0.92, y: y),
                control2: CGPoint(x: x + w, y: y + h * 0.12)
            )
            path.addLine(to: CGPoint(x: x + w * 0.7, y: y + h))
            path.closeSubpath()

            ctx.addPath(path)
            ctx.setLineWidth(s * 0.08)
            ctx.setLineJoin(.round)
            ctx.setLineCap(.round)

            // 填充 + 描边
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fillPath()

            return true
        }

        // 设置为 template image，macOS 会自动根据亮/暗模式着色
        image.isTemplate = true
        return image
    }

    /// 带勾号的盾牌（保护中状态）
    static func shieldChecked() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let ctx = NSGraphicsContext.current!.cgContext
            let s = rect.width
            let inset = s * 0.12
            let r = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)

            // 盾牌轮廓
            let path = CGMutablePath()
            let w = r.width
            let h = r.height
            let x = r.minX
            let y = r.minY

            path.move(to: CGPoint(x: x + w * 0.3, y: y + h))
            path.addLine(to: CGPoint(x: x, y: y + h * 0.35))
            path.addCurve(
                to: CGPoint(x: x + w * 0.2, y: y),
                control1: CGPoint(x: x, y: y + h * 0.12),
                control2: CGPoint(x: x + w * 0.08, y: y)
            )
            path.addLine(to: CGPoint(x: x + w * 0.8, y: y))
            path.addCurve(
                to: CGPoint(x: x + w, y: y + h * 0.35),
                control1: CGPoint(x: x + w * 0.92, y: y),
                control2: CGPoint(x: x + w, y: y + h * 0.12)
            )
            path.addLine(to: CGPoint(x: x + w * 0.7, y: y + h))
            path.closeSubpath()

            ctx.addPath(path)
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fillPath()

            // 上移勾号位置
            let cy = y + h * 0.58
            let cx = x + w * 0.5
            let csize = w * 0.38

            // 用白色画勾号（template 模式下实际上是镂空效果）
            ctx.setBlendMode(.clear)
            let check = CGMutablePath()
            let ckx = cx - csize * 0.4
            let cky = cy - csize * 0.25
            check.move(to: CGPoint(x: ckx, y: cky + csize * 0.5))
            check.addLine(to: CGPoint(x: ckx + csize * 0.35, y: cky + csize * 0.85))
            check.addLine(to: CGPoint(x: ckx + csize * 0.95, y: cky - csize * 0.05))
            ctx.addPath(check)
            ctx.setLineWidth(s * 0.08)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.setStrokeColor(NSColor.black.cgColor)
            ctx.setBlendMode(.normal)
            ctx.strokePath()

            return true
        }

        image.isTemplate = true
        return image
    }
}
