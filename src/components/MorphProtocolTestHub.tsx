import React, { useState } from 'react';
import { Tabs, Card } from 'antd';
import { TestMorphProtocol } from './TestMorphProtocol';
import { MorphProtocolBatchTest } from './MorphProtocolBatchTest';

const { TabPane } = Tabs;

export const MorphProtocolTestHub: React.FC = () => {
  const [activeTab, setActiveTab] = useState('single');

  return (
    <div style={{ padding: '20px' }}>
      <Card>
        <Tabs activeKey={activeTab} onChange={setActiveTab} size="large">
          <TabPane tab="🔧 单次测试" key="single">
            <TestMorphProtocol />
          </TabPane>
          <TabPane tab="🧪 批量测试" key="batch">
            <MorphProtocolBatchTest />
          </TabPane>
        </Tabs>
      </Card>
    </div>
  );
};
