import { useEffect, useState } from 'react';
import { Capacitor } from '@capacitor/core';
import { Camera } from '@capacitor/camera';

export function PluginDebug() {
    const [debugInfo, setDebugInfo] = useState<string[]>([]);

    useEffect(() => {
        const checkPlugins = async () => {
            const info: string[] = [];
            
            // 检查平台
            const platform = Capacitor.getPlatform();
            info.push(`平台: ${platform}`);
            
            // 检查是否为原生平台
            const isNative = Capacitor.isNativePlatform();
            info.push(`原生平台: ${isNative ? '是' : '否'}`);
            
            // 测试官方插件（Camera）
            try {
                // 只检查插件是否可用，不实际调用
                info.push(`Camera 插件: ${Camera ? '可用' : '不可用'}`);
            } catch (err: any) {
                info.push(`Camera 插件检查失败: ${err.message}`);
            }
            
            // 检查 WireGuard 插件
            try {
                const { default: WireGuard } = await import('../plugins/wireguard');
                info.push('WireGuard 模块已加载');
                
                // 尝试调用插件
                try {
                    const status = await WireGuard.getStatus();
                    info.push(`✅ 插件调用成功: ${JSON.stringify(status)}`);
                } catch (err: any) {
                    info.push(`❌ 插件调用失败: ${err.message}`);
                    
                    // 如果是 web 平台，这是正常的
                    if (platform === 'web') {
                        info.push('💡 提示: 在 Web 平台上插件不可用是正常的');
                        info.push('💡 请在 iOS 设备上测试');
                    }
                }
            } catch (err: any) {
                info.push(`模块加载失败: ${err.message}`);
            }
            
            setDebugInfo(info);
        };
        
        checkPlugins();
    }, []);

    return (
        <div style={{ 
            backgroundColor: '#1a1a1a', 
            padding: '10px', 
            marginTop: '10px',
            borderRadius: '5px',
            fontSize: '11px',
            color: '#00ff00',
            fontFamily: 'monospace',
            maxHeight: '200px',
            overflowY: 'auto'
        }}>
            <div style={{ color: '#ffff00', marginBottom: '5px' }}>🔍 插件调试信息:</div>
            {debugInfo.map((info, index) => (
                <div key={index} style={{ marginLeft: '10px', marginBottom: '2px' }}>• {info}</div>
            ))}
        </div>
    );
}
