import React, { useState, useEffect } from 'react';
import { Button, message, Card, Select, Input, Space } from 'antd';
import { Capacitor } from '@capacitor/core';
import { MorphProtocol } from '@morphvpn/capacitor-morphprotocol';

const { Option } = Select;

export const TestMorphProtocol: React.FC = () => {
  const [status, setStatus] = useState<string>('disconnected');
  const [host, setHost] = useState('your-server.com');
  const [port, setPort] = useState(51821);
  const [encryptionKey, setEncryptionKey] = useState('XuNgTBIiWFXHSeunT/xPi6DEp98vjw6XBoGogtIJbE8=:4jww75fhLvms4akS');
  const [layer, setLayer] = useState(3);
  const [padding, setPadding] = useState(8);
  const [templateType, setTemplateType] = useState(1);
  const [receivedData, setReceivedData] = useState<string[]>([]);

  const platform = Capacitor.getPlatform();

  useEffect(() => {
    MorphProtocol.addListener('statusChanged', (data: any) => {
      console.log('Status changed:', data);
      setStatus(data.status);
      message.info(`状态: ${data.status}`);
    });

    MorphProtocol.addListener('dataReceived', (data: any) => {
      console.log('Data received:', data);
      try {
        const decoded = atob(data.data);
        setReceivedData(prev => [...prev, decoded]);
        message.success(`收到数据: ${decoded.substring(0, 50)}...`);
      } catch (e) {
        console.error('Failed to decode data:', e);
      }
    });

    return () => {
      MorphProtocol.removeAllListeners();
    };
  }, []);

  const handleConnect = async () => {
    try {
      if (platform === 'web') {
        message.warning('MorphProtocol 不支持 Web 平台，请在 iOS 设备上测试', 3);
        return;
      }

      message.loading('正在连接 MorphProtocol...', 0);

      const result = await MorphProtocol.connect({
        host,
        port,
        encryptionKey,
        obfuscationLayer: layer,
        paddingLength: padding,
        templateType,
      });

      message.destroy();

      if (result.success) {
        message.success('连接成功！');
      } else {
        message.error(`连接失败: ${result.message}`);
      }
    } catch (error: any) {
      console.error('Connect failed:', error);
      message.destroy();
      message.error(`连接失败: ${error.message}`);
    }
  };

  const handleDisconnect = async () => {
    try {
      const result = await MorphProtocol.disconnect();
      if (result.success) {
        message.success('已断开连接');
        setStatus('disconnected');
      }
    } catch (error: any) {
      message.error(`断开失败: ${error.message}`);
    }
  };

  const handleSendTest = async () => {
    try {
      const testData = 'Hello, MorphProtocol! ' + new Date().toISOString();
      const base64Data = btoa(testData);

      const result = await MorphProtocol.send({
        data: base64Data,
      });

      if (result.success) {
        message.success('测试数据已发送');
      } else {
        message.error(`发送失败: ${result.message}`);
      }
    } catch (error: any) {
      message.error(`发送失败: ${error.message}`);
    }
  };

  return (
    <Card title="MorphProtocol 独立测试" style={{ margin: '20px' }}>
      <Space direction="vertical" style={{ width: '100%' }} size="large">
        <div>
          <h3>连接配置</h3>
          <Space direction="vertical" style={{ width: '100%' }}>
            <Input
              addonBefore="服务器"
              value={host}
              onChange={(e) => setHost(e.target.value)}
              disabled={status === 'connected'}
            />
            <Input
              addonBefore="端口"
              type="number"
              value={port}
              onChange={(e) => setPort(Number(e.target.value))}
              disabled={status === 'connected'}
            />
            <Input.TextArea
              rows={2}
              value={encryptionKey}
              onChange={(e) => setEncryptionKey(e.target.value)}
              placeholder="加密密钥"
              disabled={status === 'connected'}
            />
            <Select
              style={{ width: '100%' }}
              value={layer}
              onChange={setLayer}
              disabled={status === 'connected'}
            >
              <Option value={1}>1层</Option>
              <Option value={2}>2层</Option>
              <Option value={3}>3层（推荐）</Option>
              <Option value={4}>4层</Option>
            </Select>
            <Select
              style={{ width: '100%' }}
              value={templateType}
              onChange={setTemplateType}
              disabled={status === 'connected'}
            >
              <Option value={0}>无模板</Option>
              <Option value={1}>QUIC（推荐）</Option>
              <Option value={2}>KCP</Option>
              <Option value={3}>游戏协议</Option>
            </Select>
          </Space>
        </div>

        <div>
          <h3>状态: {status}</h3>
        </div>

        <Space>
          <Button 
            type="primary" 
            onClick={handleConnect}
            disabled={status === 'connected'}
          >
            连接
          </Button>
          <Button 
            onClick={handleDisconnect}
            disabled={status !== 'connected'}
          >
            断开
          </Button>
          <Button 
            onClick={handleSendTest}
            disabled={status !== 'connected'}
          >
            发送测试
          </Button>
        </Space>

        {receivedData.length > 0 && (
          <div>
            <h3>接收数据 ({receivedData.length})</h3>
            <div style={{ 
              maxHeight: '200px', 
              overflow: 'auto',
              background: '#f5f5f5',
              padding: '10px',
              borderRadius: '4px'
            }}>
              {receivedData.map((data, index) => (
                <div key={index}>[{index + 1}] {data}</div>
              ))}
            </div>
          </div>
        )}

        <div style={{ fontSize: '12px', color: '#999' }}>
          平台: {platform} {platform === 'web' && '(仅支持 iOS)'}
        </div>
      </Space>
    </Card>
  );
};
