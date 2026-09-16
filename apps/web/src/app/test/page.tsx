'use client'
import { useEffect, useRef, useState } from 'react'
import { Card, CardContent } from '@/components/ui/card'

export default function TestPage() {
  const cardRef = useRef<HTMLDivElement>(null)
  const contentRef = useRef<HTMLDivElement>(null)
  const [val, setVal] = useState('')
  const [pad, setPad] = useState('')
  useEffect(() => {
    if (cardRef.current) {
      setVal(getComputedStyle(cardRef.current).getPropertyValue('--card-spacing'))
    }
    if (contentRef.current) {
      setPad(getComputedStyle(contentRef.current).paddingLeft)
    }
  }, [])
  return (
    <Card ref={cardRef}>
      <CardContent ref={contentRef}>
        <div id="result">--card-spacing is: "{val}", padding-left is: "{pad}"</div>
      </CardContent>
    </Card>
  )
}
