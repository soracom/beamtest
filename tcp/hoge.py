                    log(level='ERROR', message='Failed to deliver message', reason=results[i].get('message',results[i].get('reason','')), originalData=[records[i]])
