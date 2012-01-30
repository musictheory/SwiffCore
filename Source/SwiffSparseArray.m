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
@end


@implementation SwiffSparseArray

- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)count
{
    NSUInteger i = state->state;
    NSUInteger o = 0;

    while ((o < count) && (i < 65536)) {
        id object = SwiffSparseArrayGetObjectAtIndex(self, i);

        if (object) {
            buffer[o++] = object;

        // Did we fail because we have no bucket?
        // If so, skip over the entire non-existant bucket
        } else if (!m_buckets[i >> 8]) {
            i += 256;
            continue;
        }

        i++;
    }

    state->state = i;
    state->itemsPtr = buffer;
    state->mutationsPtr = &state->extra[0];
        
    return o;
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
        bucket->m_objects[lowByte] = object;
    }
}


@end
