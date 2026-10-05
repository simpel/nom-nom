'use client'

import { useMemo } from 'react'
import { useRouter } from 'next/navigation'
import {
  Background,
  Controls,
  Handle,
  Position,
  ReactFlow,
  type Edge,
  type Node,
  type NodeProps,
} from '@xyflow/react'
import '@xyflow/react/dist/style.css'

// A read-only relation graph laid out in columns, left to right. Every node links to
// its detail page; the focus node is the page you are on.

export type GraphKind = 'term' | 'trait' | 'tag' | 'verdict' | 'dish'

export type GraphNode = {
  id: string
  label: string
  sub?: string
  kind: GraphKind
  column: number
  href?: string
  focus?: boolean
  /** Tags: good (true) or problem (false). */
  positive?: boolean
}

export type GraphEdge = { from: string; to: string; label?: string }

type RelationNodeData = Omit<GraphNode, 'id' | 'column'>

const COLUMN_WIDTH = 360
const SUB_COLUMN_WIDTH = 260
const ROW_HEIGHT = 64

const KIND_STYLES: Record<GraphKind, string> = {
  term: 'bg-white border-gray-300',
  trait: 'bg-indigo-50 border-indigo-300',
  tag: 'bg-white border-gray-300',
  verdict: 'bg-gray-100 border-gray-300',
  dish: 'bg-white border-dashed border-gray-300',
}

function RelationNode({ data }: NodeProps<Node<RelationNodeData>>) {
  const accent =
    data.kind === 'tag' && data.positive !== undefined
      ? data.positive ? 'border-l-4 border-l-emerald-500' : 'border-l-4 border-l-amber-500'
      : ''
  return (
    <div
      className={`w-[240px] rounded-lg border px-3 py-2 text-left shadow-sm ${KIND_STYLES[data.kind]} ${accent} ${
        data.focus ? 'ring-2 ring-black' : ''
      } ${data.href ? 'cursor-pointer hover:shadow-md' : ''}`}
    >
      <Handle type="target" position={Position.Left} className="!bg-gray-400" />
      <div className="text-[10px] font-semibold uppercase tracking-wider text-gray-500">{data.kind}</div>
      <div className="truncate text-sm font-semibold text-black">{data.label}</div>
      {data.sub && <div className="truncate text-xs text-gray-500">{data.sub}</div>}
      <Handle type="source" position={Position.Right} className="!bg-gray-400" />
    </div>
  )
}

const nodeTypes = { relation: RelationNode }

export default function RelationGraph({
  nodes,
  edges,
  height = 560,
  maxRows = 14,
}: {
  nodes: GraphNode[]
  edges: GraphEdge[]
  height?: number
  /** Rows before a column wraps into another sub-column. */
  maxRows?: number
}) {
  const router = useRouter()

  const { flowNodes, flowEdges } = useMemo(() => {
    const byColumn = new Map<number, GraphNode[]>()
    for (const n of nodes) byColumn.set(n.column, [...(byColumn.get(n.column) ?? []), n])
    const columns = [...byColumn.keys()].sort((a, b) => a - b)
    // A column longer than maxRows wraps into side-by-side sub-columns.
    const rowsIn = (list: GraphNode[]) => Math.min(list.length, maxRows)
    const tallest = Math.max(1, ...columns.map(c => rowsIn(byColumn.get(c)!)))

    const flowNodes: Node<RelationNodeData>[] = []
    let x = 0
    for (const column of columns) {
      const list = byColumn.get(column)!
      // centre each column against the tallest one
      const offset = ((tallest - rowsIn(list)) * ROW_HEIGHT) / 2
      list.forEach((n, i) => {
        const { id, column: _column, ...data } = n
        void _column
        flowNodes.push({
          id,
          type: 'relation',
          position: {
            x: x + Math.floor(i / maxRows) * SUB_COLUMN_WIDTH,
            y: offset + (i % maxRows) * ROW_HEIGHT,
          },
          data,
        })
      })
      x += (Math.ceil(list.length / maxRows) - 1) * SUB_COLUMN_WIDTH + COLUMN_WIDTH
    }
    const flowEdges: Edge[] = edges.map(e => ({
      id: `${e.from}->${e.to}`,
      source: e.from,
      target: e.to,
      label: e.label,
      style: { stroke: '#9ca3af' },
    }))
    return { flowNodes, flowEdges }
  }, [nodes, edges, maxRows])

  return (
    <div style={{ height }} className="w-full rounded-xl border bg-gray-50">
      <ReactFlow
        nodes={flowNodes}
        edges={flowEdges}
        nodeTypes={nodeTypes}
        nodesDraggable={false}
        nodesConnectable={false}
        elementsSelectable={false}
        onNodeClick={(_, node) => {
          const href = (node.data as RelationNodeData).href
          if (href) router.push(href)
        }}
        fitView
        minZoom={0.1}
        proOptions={{ hideAttribution: true }}
      >
        <Background />
        <Controls showInteractive={false} />
      </ReactFlow>
    </div>
  )
}
