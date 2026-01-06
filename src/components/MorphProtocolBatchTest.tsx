import React, { useState } from 'react';
import { Button, Card, Checkbox, Table, Progress, Space, message, Tag, Statistic, Row, Col } from 'antd';
import { Capacitor } from '@capacitor/core';
import { MorphProtocol } from '@morphvpn/capacitor-morphprotocol';

interface TestConfig {
  layer: number;
  padding: number;
  templateType: number;
  templateName: string;
}

interface TestResult {
  id: string;
  layer: number;
  padding: number;
  templateType: number;
  templateName: string;
  status: 'pending' | 'testing' | 'success' | 'failed';
  duration?: number;
  error?: string;
  timestamp?: string;
}

export const MorphProtocolBatchTest: React.FC = () => {
  const [host, setHost] = useState('192.168.0.105');
  const [port, setPort] = useState(12301);
  const [encryptionKey, setEncryptionKey] = useState('5GyRGmlcLEPoisGEZ7/GwDPqRD25k9+Eb4fcRizo+6k=:kYVe55c+rVYcFfpcM/gr0g==');
  
  // 测试配置选择
  const [selectedLayers, setSelectedLayers] = useState<number[]>([1, 2, 3, 4]);
  const [selectedPaddings, setSelectedPaddings] = useState<number[]>([4, 8, 12, 16]);
  const [selectedTemplates, setSelectedTemplates] = useState<number[]>([0, 1, 2, 3]);
  
  // 测试状态
  const [testing, setTesting] = useState(false);
  const [results, setResults] = useState<TestResult[]>([]);
  const [currentTest, setCurrentTest] = useState<number>(0);
  const [totalTests, setTotalTests] = useState<number>(0);

  const platform = Capacitor.getPlatform();

  const templateNames: { [key: number]: string } = {
    0: 'None',
    1: 'QUIC',
    2: 'KCP',
    3: 'Gaming'
  };

  // 生成测试配置
  const generateTestConfigs = (): TestConfig[] => {
    const configs: TestConfig[] = [];
    
    for (const layer of selectedLayers) {
      for (const padding of selectedPaddings) {
        for (const templateType of selectedTemplates) {
          configs.push({
            layer,
            padding,
            templateType,
            templateName: templateNames[templateType]
          });
        }
      }
    }
    
    return configs;
  };

  // 执行单个测试
  const runSingleTest = async (config: TestConfig): Promise<TestResult> => {
    const testId = `L${config.layer}-P${config.padding}-T${config.templateType}`;
    const startTime = Date.now();
    
    try {
      console.log(`🧪 Testing: ${testId}`);
      
      // 连接
      await MorphProtocol.connect({
        host,
        port,
        encryptionKey,
        obfuscationLayer: config.layer,
        paddingLength: config.padding,
        templateType: config.templateType
      });
      
      // 等待连接稳定
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // 检查状态
      const statusResult = await MorphProtocol.getStatus();
      
      // 断开连接
      await MorphProtocol.disconnect();
      
      // 等待断开完成
      await new Promise(resolve => setTimeout(resolve, 500));
      
      const duration = Date.now() - startTime;
      
      if (statusResult.status === 'connected') {
        return {
          id: testId,
          ...config,
          status: 'success',
          duration,
          timestamp: new Date().toISOString()
        };
      } else {
        return {
          id: testId,
          ...config,
          status: 'failed',
          duration,
          error: `Status: ${statusResult.status}`,
          timestamp: new Date().toISOString()
        };
      }
    } catch (error: any) {
      const duration = Date.now() - startTime;
      
      // 尝试断开连接
      try {
        await MorphProtocol.disconnect();
      } catch (e) {
        // 忽略断开错误
      }
      
      return {
        id: testId,
        ...config,
        status: 'failed',
        duration,
        error: error.message || String(error),
        timestamp: new Date().toISOString()
      };
    }
  };

  // 开始批量测试
  const startBatchTest = async () => {
    if (platform === 'web') {
      message.warning('MorphProtocol 不支持 Web 平台，请在 iOS 设备上测试');
      return;
    }

    const configs = generateTestConfigs();
    
    if (configs.length === 0) {
      message.warning('请至少选择一个测试配置');
      return;
    }

    setTesting(true);
    setResults([]);
    setCurrentTest(0);
    setTotalTests(configs.length);

    message.info(`开始测试 ${configs.length} 个配置组合`);

    const testResults: TestResult[] = [];

    for (let i = 0; i < configs.length; i++) {
      const config = configs[i];
      setCurrentTest(i + 1);

      // 添加待测试状态
      const pendingResult: TestResult = {
        id: `L${config.layer}-P${config.padding}-T${config.templateType}`,
        ...config,
        status: 'testing'
      };
      setResults([...testResults, pendingResult]);

      // 执行测试
      const result = await runSingleTest(config);
      testResults.push(result);
      setResults([...testResults]);

      console.log(`✅ ✅ ✅ ✅ Test ${i + 1}/${configs.length} completed:`, result);
      await new Promise(resolve => setTimeout(resolve, 3000));
    }

    setTesting(false);
    
    const successCount = testResults.filter(r => r.status === 'success').length;
    const failCount = testResults.filter(r => r.status === 'failed').length;
    
    message.success(`测试完成！成功: ${successCount}, 失败: ${failCount}`);
  };

  // 停止测试
  const stopTest = async () => {
    setTesting(false);
    try {
      await MorphProtocol.disconnect();
    } catch (e) {
      // 忽略错误
    }
    message.info('测试已停止');
  };

  // 导出结果
  const exportResults = () => {
    const csv = [
      ['ID', 'Layer', 'Padding', 'Template', 'Status', 'Duration(ms)', 'Error', 'Timestamp'].join(','),
      ...results.map(r => [
        r.id,
        r.layer,
        r.padding,
        r.templateName,
        r.status,
        r.duration || '',
        r.error || '',
        r.timestamp || ''
      ].join(','))
    ].join('\n');

    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `morphprotocol-test-${Date.now()}.csv`;
    a.click();
    URL.revokeObjectURL(url);
    
    message.success('测试结果已导出');
  };

  // 计算统计数据
  const stats = {
    total: results.length,
    success: results.filter(r => r.status === 'success').length,
    failed: results.filter(r => r.status === 'failed').length,
    successRate: results.length > 0 
      ? ((results.filter(r => r.status === 'success').length / results.length) * 100).toFixed(1)
      : '0',
    avgDuration: results.length > 0
      ? (results.reduce((sum, r) => sum + (r.duration || 0), 0) / results.length).toFixed(0)
      : '0'
  };

  // 表格列定义
  const columns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 120,
      fixed: 'left' as const
    },
    {
      title: '混淆层数',
      dataIndex: 'layer',
      key: 'layer',
      width: 100,
      sorter: (a: TestResult, b: TestResult) => a.layer - b.layer
    },
    {
      title: '填充长度',
      dataIndex: 'padding',
      key: 'padding',
      width: 100,
      sorter: (a: TestResult, b: TestResult) => a.padding - b.padding
    },
    {
      title: '协议模板',
      dataIndex: 'templateName',
      key: 'templateName',
      width: 100,
      filters: [
        { text: 'None', value: 'None' },
        { text: 'QUIC', value: 'QUIC' },
        { text: 'KCP', value: 'KCP' },
        { text: 'Gaming', value: 'Gaming' }
      ],
      onFilter: (value: any, record: TestResult) => record.templateName === value
    },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      width: 100,
      render: (status: string) => {
        const colors: { [key: string]: string } = {
          pending: 'default',
          testing: 'processing',
          success: 'success',
          failed: 'error'
        };
        const labels: { [key: string]: string } = {
          pending: '待测试',
          testing: '测试中',
          success: '成功',
          failed: '失败'
        };
        return <Tag color={colors[status]}>{labels[status]}</Tag>;
      },
      filters: [
        { text: '成功', value: 'success' },
        { text: '失败', value: 'failed' }
      ],
      onFilter: (value: any, record: TestResult) => record.status === value
    },
    {
      title: '耗时(ms)',
      dataIndex: 'duration',
      key: 'duration',
      width: 100,
      sorter: (a: TestResult, b: TestResult) => (a.duration || 0) - (b.duration || 0),
      render: (duration?: number) => duration ? duration.toFixed(0) : '-'
    },
    {
      title: '错误信息',
      dataIndex: 'error',
      key: 'error',
      ellipsis: true,
      render: (error?: string) => error || '-'
    }
  ];

  return (
    <div style={{ padding: '20px' }}>
      <Card title="🧪 MorphProtocol 批量测试工具" style={{ marginBottom: 20 }}>
        {/* 服务器配置 */}
        <Card type="inner" title="服务器配置" style={{ marginBottom: 20 }}>
          <Space direction="vertical" style={{ width: '100%' }}>
            <div>
              <label>服务器地址: </label>
              <input
                type="text"
                value={host}
                onChange={(e) => setHost(e.target.value)}
                disabled={testing}
                style={{ width: 200, marginLeft: 10 }}
              />
            </div>
            <div>
              <label>端口: </label>
              <input
                type="number"
                value={port}
                onChange={(e) => setPort(Number(e.target.value))}
                disabled={testing}
                style={{ width: 200, marginLeft: 10 }}
              />
            </div>
            <div>
              <label>加密密钥: </label>
              <input
                type="text"
                value={encryptionKey}
                onChange={(e) => setEncryptionKey(e.target.value)}
                disabled={testing}
                style={{ width: 500, marginLeft: 10 }}
              />
            </div>
          </Space>
        </Card>

        {/* 测试配置选择 */}
        <Card type="inner" title="测试配置" style={{ marginBottom: 20 }}>
          <Space direction="vertical" style={{ width: '100%' }}>
            <div>
              <label style={{ fontWeight: 'bold' }}>混淆层数:</label>
              <Checkbox.Group
                options={[
                  { label: '1层', value: 1 },
                  { label: '2层', value: 2 },
                  { label: '3层', value: 3 },
                  { label: '4层', value: 4 }
                ]}
                value={selectedLayers}
                onChange={(values) => setSelectedLayers(values as number[])}
                disabled={testing}
                style={{ marginLeft: 10 }}
              />
            </div>
            <div>
              <label style={{ fontWeight: 'bold' }}>填充长度:</label>
              <Checkbox.Group
                options={[
                  { label: '4字节', value: 4 },
                  { label: '8字节', value: 8 },
                  { label: '12字节', value: 12 },
                  { label: '16字节', value: 16 }
                ]}
                value={selectedPaddings}
                onChange={(values) => setSelectedPaddings(values as number[])}
                disabled={testing}
                style={{ marginLeft: 10 }}
              />
            </div>
            <div>
              <label style={{ fontWeight: 'bold' }}>协议模板:</label>
              <Checkbox.Group
                options={[
                  { label: 'None (无)', value: 0 },
                  { label: 'QUIC', value: 1 },
                  { label: 'KCP', value: 2 },
                  { label: 'Gaming', value: 3 }
                ]}
                value={selectedTemplates}
                onChange={(values) => setSelectedTemplates(values as number[])}
                disabled={testing}
                style={{ marginLeft: 10 }}
              />
            </div>
            <div style={{ marginTop: 10 }}>
              <Tag color="blue">
                将测试 {selectedLayers.length} × {selectedPaddings.length} × {selectedTemplates.length} = {selectedLayers.length * selectedPaddings.length * selectedTemplates.length} 个配置组合
              </Tag>
            </div>
          </Space>
        </Card>

        {/* 控制按钮 */}
        <Space>
          <Button
            type="primary"
            onClick={startBatchTest}
            disabled={testing}
            size="large"
          >
            开始批量测试
          </Button>
          <Button
            danger
            onClick={stopTest}
            disabled={!testing}
            size="large"
          >
            停止测试
          </Button>
          <Button
            onClick={exportResults}
            disabled={results.length === 0}
            size="large"
          >
            导出结果 (CSV)
          </Button>
          <Button
            onClick={() => setResults([])}
            disabled={testing || results.length === 0}
            size="large"
          >
            清空结果
          </Button>
        </Space>

        {/* 测试进度 */}
        {testing && (
          <div style={{ marginTop: 20 }}>
            <Progress
              percent={totalTests > 0 ? Math.round((currentTest / totalTests) * 100) : 0}
              status="active"
              format={() => `${currentTest} / ${totalTests}`}
            />
          </div>
        )}
      </Card>

      {/* 统计信息 */}
      {results.length > 0 && (
        <Card title="📊 测试统计" style={{ marginBottom: 20 }}>
          <Row gutter={16}>
            <Col span={6}>
              <Statistic title="总测试数" value={stats.total} />
            </Col>
            <Col span={6}>
              <Statistic title="成功" value={stats.success} valueStyle={{ color: '#3f8600' }} />
            </Col>
            <Col span={6}>
              <Statistic title="失败" value={stats.failed} valueStyle={{ color: '#cf1322' }} />
            </Col>
            <Col span={6}>
              <Statistic title="成功率" value={stats.successRate} suffix="%" />
            </Col>
          </Row>
          <Row gutter={16} style={{ marginTop: 20 }}>
            <Col span={6}>
              <Statistic title="平均耗时" value={stats.avgDuration} suffix="ms" />
            </Col>
          </Row>
        </Card>
      )}

      {/* 测试结果表格 */}
      {results.length > 0 && (
        <Card title="📋 测试结果">
          <Table
            columns={columns}
            dataSource={results}
            rowKey="id"
            pagination={{ pageSize: 20 }}
            scroll={{ x: 1000 }}
            size="small"
          />
        </Card>
      )}
    </div>
  );
};
