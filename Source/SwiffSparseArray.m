/*
    SwiffSparseArray.h
    Copyright (c) 2011-2012, musictheory.net, LLC.  All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright
          notice, this list of conditions and the following disclaimer in the
          documentation and/or other materials provided with the distribution.
        * Neither the name of musictheory.net, LLC nor the names of its contributors
          may be used to endorse or promote products derived from this software
          without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL MUSICTHEORY.NET, LLC BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "SwiffSparseArray.h"

@interface SwiffSparseArrayBucket : NSObject {
@package
    NSObject *m_objects[256];
}
@end


@implementation SwiffSparseArrayBucket

- (void) dealloc
{
    for (NSInteger i = 0; i < 256; i++) {
        [m_objects[i] release];
        m_objects[i] = nil;
    }
    
    [super dealloc];
}

@end


@implementation SwiffSparseArray

- (void) dealloc
{
    for (NSInteger i = 0; i < 256; i++) {
        [m_buckets[i] release];
        m_buckets[i] = nil;
    }
    
    [super dealloc];
}

- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)count
{
    NSInteger highByte = state->state >> 8;
    NSInteger lowByte  = state->state & 0xFF;

    NSUInteger i = 0;

    for ( ; highByte < 256; highByte++) {
        SwiffSparseArrayBucket *bucket = m_buckets[highByte];

        if (bucket) {
            for ( ; lowByte < 256; lowByte++) {
                id object = bucket->m_objects[lowByte];
                if (object) {
                    buffer[i++] = object;
                    if (i == count) goto end;
                }
            }
        }

        if (highByte != 255) {
            lowByte = 0;
        }
    }

end:
    state->state = (highByte << 8) | lowByte;
    state->itemsPtr = buffer;
    state->mutationsPtr = &state->extra[0];
        
    return i;
}


- (void) setObject:(id)object atIndex:(UInt16)index
{
    SwiffSparseArraySetObjectAtIndex(self, index, object);
}


- (id) objectAtIndex:(UInt16)index;
{
    return SwiffSparseArrayGetObjectAtIndex(self, index);
}


id SwiffSparseArrayGetObjectAtIndex(SwiffSparseArray *self, UInt16 index)
{
    if (!self) return nil;

    UInt8 highByte = index >> 8;
    UInt8 lowByte  = index & 0xFF;

    SwiffSparseArrayBucket *bucket = self->m_buckets[highByte];

    if (bucket) {
        return bucket->m_objects[lowByte];
    } else {
        return nil;
    }
}


void SwiffSparseArraySetObjectAtIndex(SwiffSparseArray *self, UInt16 index, id object)
{
    if (!self) return;

    UInt8 highByte = index >> 8;
    UInt8 lowByte  = index & 0xFF;

    SwiffSparseArrayBucket *bucket = self->m_buckets[highByte];
    if (!bucket) {
        bucket = self->m_buckets[highByte] = [[SwiffSparseArrayBucket alloc] init];
    }

    if (bucket) {
        [bucket->m_objects[lowByte] release];
        bucket->m_objects[lowByte] = [object retain];
    }
}


@end
