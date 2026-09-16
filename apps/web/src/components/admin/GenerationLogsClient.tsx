'use client'

import { useState } from 'react'

export default function GenerationLogsClient({ logs }: { logs: any[] }) {
  const [expandedId, setExpandedId] = useState<string | null>(null)

  if (!logs || logs.length === 0) {
    return <div className="text-gray-500 italic">No generation logs available.</div>
  }

  return (
    <div className="space-y-4">
      {logs.map(log => {
        const isExpanded = expandedId === log.id
        const isError = log.status === 'error'
        const isRunning = log.status === 'running'
        
        let statusBadge = <span className="px-2 py-0.5 rounded text-xs bg-green-100 text-green-800 font-medium">Success</span>
        if (isError) statusBadge = <span className="px-2 py-0.5 rounded text-xs bg-red-100 text-red-800 font-medium">Error</span>
        if (isRunning) statusBadge = <span className="px-2 py-0.5 rounded text-xs bg-yellow-100 text-yellow-800 font-medium">Running</span>

        return (
          <div key={log.id} className="border rounded-md overflow-hidden bg-white shadow-sm">
            <div 
              className="px-4 py-3 bg-gray-50 flex justify-between items-center cursor-pointer hover:bg-gray-100"
              onClick={() => setExpandedId(isExpanded ? null : log.id)}
            >
              <div className="flex items-center gap-3">
                {statusBadge}
                <span className="font-semibold text-sm capitalize">{log.generation_type.replace('_', ' ')}</span>
                <span className="text-gray-500 text-xs">{new Date(log.created_at).toLocaleString('en-US')}</span>
              </div>
              <div className="text-xs text-gray-400">
                {log.duration_ms ? `${(log.duration_ms / 1000).toFixed(1)}s` : ''} • {log.model_used}
              </div>
            </div>
            
            {isExpanded && (
              <div className="p-4 border-t space-y-4 text-sm">
                {isError && (
                  <div>
                    <span className="font-semibold text-red-600 block mb-1">Error Message:</span>
                    <pre className="bg-red-50 text-red-800 p-2 rounded whitespace-pre-wrap font-mono text-xs overflow-x-auto">{log.error_message}</pre>
                  </div>
                )}
                
                <div>
                  <span className="font-semibold block mb-1">Prompt:</span>
                  <pre className="bg-gray-100 p-3 rounded whitespace-pre-wrap font-mono text-xs overflow-x-auto max-h-64">{log.prompt}</pre>
                </div>
                
                {log.response && (
                  <div>
                    <span className="font-semibold block mb-1">Response:</span>
                    <pre className="bg-blue-50 p-3 rounded whitespace-pre-wrap font-mono text-xs overflow-x-auto max-h-96">
                      {(() => {
                        try {
                          const parsed = JSON.parse(log.response);
                          return JSON.stringify(parsed, null, 2);
                        } catch (e) {
                          return log.response;
                        }
                      })()}
                    </pre>
                  </div>
                )}
              </div>
            )}
          </div>
        )
      })}
    </div>
  )
}
